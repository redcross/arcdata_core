module Core
  class SerializedColumn < ActiveRecord::ConnectionAdapters::Column
    def type_cast(val)
      case type
      when :array then val.try(:split,',')
      else super(val)
      end
    end

    def type_cast_for_write(value)
      case value
      when Array then value.join(',')
      else super(value)
      end
    end

    def simplified_type(field_type)
      case field_type
      when 'array' then :array
      else super(field_type)
      end
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

        sql_type = case type
        when :string then 'varchar'
        when :double then 'float'
        when :time then 'timestamp'
        else type.to_s
        end

        column = SerializedColumn.new name.to_s, default, sql_type

        serialized_columns[name] = [store_attribute, column]

        define_method name do
          raw = read_store_attribute store_attribute, name
          column.type_cast(raw)
        end

        define_method :"#{name}_before_type_cast" do
          read_store_attribute store_attribute, name
        end

        define_method :"#{name}=" do |val|
          raw = column.type_cast_for_write(val)
          write_store_attribute store_attribute, name, raw
        end

        scope :"with_#{name}_present", -> do
          # `?` is the Postgres hstore operator for hash key presence
          where(":column_name ? :key", column_name: store_attribute, key: name).exists?
        end

        scope :"with_#{name}_value", ->(val) do
          # `@>` is the Postgres hstore "contains" operator and (in contrast to `->`) will use the column index for queries
          where(":column_name @> hstore(:key, :value)", column_name: store_attribute, key: name, value: value)
        end

      end

    end

  end
end
