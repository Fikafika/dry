module Dynamic
  class Elasticsearch < Base
    module Feature; extend ActiveSupport::Concern

      def self.load_constants(schema)
        schema.const_dynamic_record.include(DynamicRecord)
      end

      module DynamicRecord; extend ActiveSupport::Concern

        @@indexable_virtual_attributes = {
          'polymorphic_name' => {
            included_by_default: true,
            type: 'String',
          },
          'creator_name' => {
            included_by_default: false,
            type: 'String',
          }
        }

        def self.indexable_virtual_attributes
          @@indexable_virtual_attributes
        end

        included do
          define_singleton_method :indexable_virtual_attributes do
            @@indexable_virtual_attributes
          end
        end

      end
    end
  end
end
