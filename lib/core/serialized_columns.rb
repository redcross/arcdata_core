module Core
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

      def serialized_accessor store_attribute, name, type, default: nil
        serialized_columns[name] = [store_attribute, type]

        serialized_accessor_column_name = "#{arel_table.name}.#{store_attribute}"

        define_method name do
          public_send(store_attribute).fetch(name.to_s, nil) || default
        end

        define_method :"#{name}=" do |val|
          cast_value = case type
          when :string  then val
          when :integer then Integer(val)
          when :decimal then Float(val)
          when :boolean then
            # This is what active admin sends over from the checkbox
            if val == "0"
              false
            else
              !!val
            end
          else
            raise "Type not supported by SerializedColumns"
          end

          public_send(store_attribute).store(name.to_s, cast_value)
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
