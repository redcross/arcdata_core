module Core
  class SerializedColumn < ActiveRecord::ConnectionAdapters::Column
    class ArrayType < ::ActiveRecord::Type::Value
      def cast(value)
        return value.try(:split, ',')
      end

      def serialize(value)
        return val.join(',')
      end
    end

    CAST_TYPES = {
      boolean: ::ActiveRecord::Type::Boolean,
      integer: ::ActiveRecord::Type::Integer,
      string: ::ActiveRecord::Type::String,
      float: ::ActiveRecord::Type::Float,
      date: ::ActiveRecord::Type::Date,
      datetime: ::ActiveRecord::Type::DateTime,
      decimal: ::ActiveRecord::Type::Decimal,
      array: ArrayType,
      any: ::ActiveRecord::Type::Value,
    }

    def initialize(name, default, cast_type, sql_type = nil, null = true)
      super
      @cast_type = CAST_TYPES.fetch(cast_type).new
    end
  end

  module SerializedColumns
    extend ActiveSupport::Concern

    # ActiveRecord redefines this for names that are in the columns hash (as we override), to
    # search in the @attributes list.  But obviously, that won't be there for this type of property.
    def has_attribute?(attr)
      if config = self.class.serialized_columns[attr.to_sym]
        super(config.first)
      else
        super(attr)
      end
    end

    module ClassMethods

      def serialized_columns
        @serialized_columns ||= {}
      end

      def store_attribute_columns
        serialized_columns.values.map(&:first)
      end

      def content_columns
        super.reject{|c| store_attribute_columns.include? c.name.to_sym }
      end

      def columns
        super + serialized_columns.values.map(&:last)
      end

      def serialized_accessor store_attribute, name, type, default: nil
        column = SerializedColumn.new name.to_s, default, type

        serialized_accessor_column_name = "#{arel_table.name}.#{store_attribute}"

        sql_type = case column.type
        when :string then 'varchar'
        when :double then 'float'
        when :time then 'timestamp'
        else type.to_s
        end

        serialized_columns[name] = [store_attribute, column]

        define_method name do
          raw = read_store_attribute store_attribute, name
          column.type_cast_from_database(raw)
        end

        define_method :"#{name}_before_type_cast" do
          read_store_attribute store_attribute, name
        end

        define_method :"#{name}=" do |val|
          raw = column.type_cast_for_database(val)
          write_store_attribute store_attribute, name, raw
        end

        scope :"with_#{name}_present", -> do
          # `?` is the Postgres operator for key presence
          where("#{serialized_accessor_column_name} ? :key", key: name)
        end

        scope :"with_#{name}_value", ->(val) do
          # `@>` is the Postgres "contains" operator and (in contrast to `->`) will use the column index for queries
          json_value = { name => val }.to_json
          where("#{serialized_accessor_column_name} @> :json_value", json_value: json_value)
        end

      end

    end

  end
end
