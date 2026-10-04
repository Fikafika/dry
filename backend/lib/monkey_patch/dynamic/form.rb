require_relative '../../../app/models/concerns/mass_assignment_skip_unknown_attributes'

# default values defined in the schema (dynamic_record) are assigned by new:
# the creation form must send them to the frontend and must not consider them
# as values entered by the user
module SchemaDefaultValuesInForm

  def self.any?(record)
    klass = record.class
    klass.try(:default_attribute_values).present? || klass.try(:associations_with_default_value).present?
  end

  # true when the current value of the attribute or association is the schema default
  def self.default_value?(record, attribute_name)
    klass = record.class
    name = attribute_name.to_s

    attribute_values = klass.try(:default_attribute_values) || {}
    return record.send(name) == attribute_values[name] if attribute_values.key?(name)

    stem = name.sub(/_ids?$/, '')
    assoc = klass.try(:associations_with_default_value)&.detect{|a| a.name == stem || a.name == stem.pluralize }
    return false unless assoc
    return Array.wrap(record.send(assoc.name)).map(&:id) == Array.wrap(assoc.default_value).map(&:id)
  end

  # Form#for_each_element_for_serialize_record skips the association elements:
  # the associations filled by the schema are added here, so that the frontend
  # gets the records (and their label) of a new record
  module EmbedAssociation
    def options_for_serialize_record(input_prefix)
      result = super
      record = record_for_input_prefix[input_prefix]
      return result unless record&.new_record?

      names = record.class.try(:associations_with_default_value)&.map(&:name) || []
      return result if names.empty?

      schema_instance_for_input_prefix(input_prefix)&.elements_from_form&.each do |e|
        next unless e.is_a?(::Dynamic::Form::Element::Association::Base) && names.include?(e.association_name)
        result.deep_merge!(include: { e.association_name => {} })
      end
      return result
    end
  end

  module SerializeRecord
    def serialized_record_for_input_prefix
      result = {}
      record_for_input_prefix.each do |input_prefix, record|
        next if record.new_record? && (!record.changed? || record.changes.keys == ['type']) && !SchemaDefaultValuesInForm.any?(record)
        o = options_for_serialize_record(input_prefix)
        result[input_prefix] = record.as_deep_json(o)
      end
      return result
    end
  end

  # only when the form is opened (FormsController#show): on submit, a value equal
  # to the schema default may have been chosen by the user and must be kept
  module DoNotBlockFormDefaultValue
    def unassigned_attribute_name_for_record?(record)
      return true if form&.opening && record.new_record? && SchemaDefaultValuesInForm.default_value?(record, attribute_name)
      super
    end
  end

end

ActiveSupport.on_load(:dynamic_form) do
  include MassAssignmentSkipUnknownAttributes

  # Association::Base and Attribute::Boolean redefine unassigned_attribute_name_for_record?
  # in their own class body, which wins over a module prepended on Element::Base.
  ::Dynamic::Form::Element::Base.prepend(SchemaDefaultValuesInForm::DoNotBlockFormDefaultValue)
  ::Dynamic::Form::Element::Association::Base.prepend(SchemaDefaultValuesInForm::DoNotBlockFormDefaultValue)
  ::Dynamic::Form::Element::Attribute::Boolean.prepend(SchemaDefaultValuesInForm::DoNotBlockFormDefaultValue)

  prepend SchemaDefaultValuesInForm::SerializeRecord
  prepend SchemaDefaultValuesInForm::EmbedAssociation

  # set by FormsController#show
  attr_accessor :opening

  concerning :Permissions do
    included do
      include UneekPermission::ControlledKlass

      def associations_for_uneek_permissions
        nil
      end
    end

    def is_public?
      self.can_be_read_by?(::UneekPermission::PredefinedReceiver::Public.instance)
    end

    def can_be_updated_by_current_user?
      return false unless current_user
      return true if current_user.admin?(self.schema_id)
      return self.can_be_updated_by?(current_user)
    end
  end

  concerning :BelongsToTheme do
    included do
      belongs_to :theme, class_name: 'Dynamic::Theme', optional: true
    end
  end

  concerning :Export do

    class_methods do

      def includes_for_export(export_options = {})
        return {
          except: export_include_exceptions(self),
          include: {
            translations: {
              as: :translations_attributes,
              except: export_include_exceptions + ['dynamic_form_id'],
            },
            elements: {
              as: :elements_attributes,
              except: export_include_exceptions(Dynamic::Form::Element::Base),
              include: {
                translations: {
                  as: :translations_attributes,
                  except: export_include_exceptions + ['dynamic_form_element_id'],
                },
                default_value_associations: {
                  as: :default_value_associations_attributes,
                  except: export_include_exceptions,
                },
                possible_values: {
                  as: :possible_values_attributes,
                  except: export_include_exceptions(Dynamic::Form::Element::PossibleValue),
                  include: {
                    translations: {
                      as: :translations_attributes,
                      except: export_include_exceptions + ['dynamic_form_element_possible_value_id'],
                    },
                  },
                },
              },
            },
            skip_update_validation_rules_from_elements: {overriden_value: true},
            mandatory_validation_rules: {
              except: export_include_exceptions,
              as: :mandatory_validation_rules_attributes,
            },
            important_validation_rules: {
              except: export_include_exceptions,
              as: :important_validation_rules_attributes,
            },
          },
        }
      end

      def export_include_exceptions(klass = nil)
        r = ['created_at', 'updated_at', 'deleted_at', 'schema_id']
        r += ['form_id'] unless klass == self
        return r unless klass
        return r +
          klass.translated_attribute_names.map(&:to_s) +
          klass.globalize_attribute_names.map(&:to_s)
      end

    end

  end

  def can_be_submitted?
    (!!(context[:submitter] || current_user) || is_public?) && !forbidden?
  end

end
