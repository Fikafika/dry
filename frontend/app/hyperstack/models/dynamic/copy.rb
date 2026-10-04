module Dynamic
  module Copy
    class Mapping < Dynamic::Base
      define_api_path

      class Pair < Dynamic::Base
        define_api_path
      end

      class HasManyRule < Dynamic::Base
        define_api_path
      end
    end

    class Setting < Dynamic::Base
      define_api_path

      MAX_COUNT_PER_SOURCE = 50

      class SourceRecord < Dynamic::Base
        define_api_path
      end
    end

    module TypeCompatibility
      extend self

      NUMERIC = %w[Integer Float Decimal].freeze
      TEXTUAL = %w[String Text TranslatableString TranslatableText].freeze
      DATELIKE = %w[Date DateTime].freeze

      def belongs_to?(field)
        field.class.name == 'Dynamic::Schema::Association::BelongsTo'
      end

      def has_many?(field)
        field.class.name == 'Dynamic::Schema::Association::HasMany'
      end

      def attachment?(field)
        field.class.name.start_with?('Dynamic::Schema::Attachment::')
      end

      def compatible?(source_field, target_field)
        return false unless source_field && target_field
        return belongs_to_compatible?(source_field, target_field) if belongs_to?(source_field) || belongs_to?(target_field)
        return attachments_compatible?(source_field, target_field) if attachment?(source_field) || attachment?(target_field)
        attributes_compatible?(source_field, target_field)
      end

      def belongs_to_compatible?(source, target)
        return false unless belongs_to?(source) && belongs_to?(target)
        source_poly = source.target_klass_id.nil?
        target_poly = target.target_klass_id.nil?
        return source_poly && target_poly if source_poly || target_poly
        source.target_klass_id == target.target_klass_id
      end

      def attachments_compatible?(source, target)
        return false unless attachment?(source) && attachment?(target)
        source.class.name == target.class.name
      end

      def attributes_compatible?(source_attr, target_attr)
        return enum_values_compatible?(source_attr, target_attr) if source_attr.type == 'Enum' || target_attr.type == 'Enum'
        return true if source_attr.type == target_attr.type
        return true if NUMERIC.include?(source_attr.type) && NUMERIC.include?(target_attr.type)
        return true if TEXTUAL.include?(source_attr.type) && TEXTUAL.include?(target_attr.type)
        return true if DATELIKE.include?(source_attr.type) && DATELIKE.include?(target_attr.type)
        false
      end

      def enum_values_compatible?(source_attr, target_attr)
        return false unless source_attr.type == 'Enum' && target_attr.type == 'Enum'
        source_values = source_attr.values.to_a.map(&:name)
        target_values = target_attr.values.to_a.map(&:name)
        return true if source_values.empty? || target_values.empty?
        (source_values - target_values).empty?
      end
    end

    module Feature; extend ActiveSupport::Concern
      def self.load_constants(schema)
        mapping_klass = schema.const_reserved_klass("Copy::Mapping", ::Dynamic::Copy::Mapping)
        pair_klass = schema.const_reserved_klass("Copy::Mapping::Pair", ::Dynamic::Copy::Mapping::Pair)
        has_many_rule_klass = schema.const_reserved_klass("Copy::Mapping::HasManyRule", ::Dynamic::Copy::Mapping::HasManyRule)
        setting_klass = schema.const_reserved_klass("Copy::Setting", ::Dynamic::Copy::Setting)
        source_record_klass = schema.const_reserved_klass("Copy::Setting::SourceRecord", ::Dynamic::Copy::Setting::SourceRecord)

        mapping_klass.has_many :pairs, class_name: pair_klass.name, inverse_of: :mapping
        mapping_klass.has_many :has_many_rules, class_name: has_many_rule_klass.name, inverse_of: :mapping

        pair_klass.belongs_to :mapping, class_name: mapping_klass.name, inverse_of: :pairs

        has_many_rule_klass.belongs_to :mapping, class_name: mapping_klass.name, inverse_of: :has_many_rules
        has_many_rule_klass.belongs_to :child_mapping, class_name: mapping_klass.name

        setting_klass.belongs_to :mapping, class_name: mapping_klass.name
        setting_klass.has_many :source_records, class_name: source_record_klass.name, inverse_of: :setting

        source_record_klass.belongs_to :setting, class_name: setting_klass.name, inverse_of: :source_records
        source_record_klass.belongs_to :record, polymorphic: true
      end
    end
  end
end
