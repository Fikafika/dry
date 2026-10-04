module Dynamic
  module Merge
    class Setting < Dynamic::Base
      define_api_path # /api/d/uneek/r__merge__settings

      def self.includes_for_load
        {
          result_record: 1,
          record_to_merges: 1,
          fields: {
            include: {
              values: {
                include: {
                  value: 1,
                  value_type: 1,
                  value_id: 1,
                },
              },
            },
          },
        }
      end

      def result_record_klass
        result = self.result_record_type.safe_constantize
        result ||= self.record_to_merges[0].class
        return result
      end
    end

    class Record < Dynamic::Base
    end

    class Field < Dynamic::Base
      define_api_path # /api/d/uneek/r__merge__fields

      def from
        self.setting.record_to_merges.detect { |r| r.id == self.from_id && r.type == self.from_type }
      end
    end

    class Value < Dynamic::Base
      define_api_path # /api/d/uneek/r__merge__values
    end

    module Feature; extend ActiveSupport::Concern
      def self.load_constants(schema)
        setting_klass = schema.const_reserved_klass("Merge::Setting", ::Dynamic::Merge::Setting)
        record_klass = schema.const_reserved_klass("Merge::Record", ::Dynamic::Merge::Record)
        field_klass = schema.const_reserved_klass("Merge::Field", ::Dynamic::Merge::Field)
        value_klass = schema.const_reserved_klass("Merge::Value", ::Dynamic::Merge::Value)

        value_klass.belongs_to :field, class_name: field_klass.name, inverse_of: :values

        field_klass.belongs_to :setting, class_name: setting_klass.name, inverse_of: :fields
        field_klass.has_many :values, class_name: value_klass.name, inverse_of: :field

        setting_klass.has_many :fields, class_name: field_klass.name, inverse_of: :setting
        setting_klass.has_many :record_to_merges, polymorphic: true
        setting_klass.belongs_to :result_record, polymorphic: true
      end
    end
  end
end
