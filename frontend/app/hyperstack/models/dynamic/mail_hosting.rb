module Dynamic
  module MailHosting
    class Rule < ::Dynamic::Base
      define_api_path # /r__uneek_mailhosting_rule

      has_many :conditions, class_name: 'Dynamic::MailHosting::Condition', foreign_key: :rule_id, inverse_of: :rule, accept_nested_attributes: true

      class << self
        def feature
          'Dynamic::MailHosting::Feature'
        end

        def name_attribute
          'name'
        end
      end

    end

    class Condition < ::Dynamic::Base
      define_api_path # /r__uneek_mailhosting_condition

      belongs_to :rule, class_name: 'Dynamic::MailHosting::Rule', inverse_of: :conditions
    end

    class Feature

      class << self
        def load_constants(schema)
          feature_schema = schema.features.detect{|f| f.name == "Dynamic::MailHosting::Feature"}

          return unless feature_schema

          email_klass = feature_schema&.concerns&.detect{|c| c.name == 'Message'}.klass

          association_class_ids = feature_schema&.options&.detect{|o| o.name == "associations_klasses" }&.value

          association_class_ids = association_class_ids ? association_class_ids : []

          schema.klasses.each do |klass|
            klass.const.define_singleton_method(:has_mailhosting_associations?) do
              association_class_ids.include?(klass.id)
            end
          end

          schema.const.define_singleton_method(:mailhosting_email_klass) do
            email_klass&.const
          end
        end

      end

      module Contextualization; extend ActiveSupport::Concern

        class_methods do
          def klass_context(klass)
            kcontext = {
              klass_name: klass.name,
              attributes: klass.attribute_names,
              attachments: klass.attachment_reflections(true).keys
            }

            kcontext[:associations] = {}
            klass.reflect_on_all_associations(true).each do |assoc_reflec|
              kcontext[:associations][assoc_reflec.name] = assoc_reflec.klass
            end

            kcontext
          end
        end

      end;

      module Serialization
        extend ActiveSupport::Concern
        include Contextualization


        class_methods do
          def includes_for_dot_keys(klass, variables)
            includes = {include: {}, only: []}

            variables.each do |variable|
              current_includes = includes
              current_context = klass_context(klass)
              keys = variable.split('.')

              keys.each_with_index do |key, index|
                # skip numbers array index
                next if key.to_s == key.to_i.to_s

                if current_context[:attributes].include?(key)
                  current_includes[:only] << key
                  break
                end

                key_sym = key.to_sym

                if current_context[:associations].has_key?(key)
                  current_includes[:include][key_sym] = {include: {}, only: []} unless current_includes[:include][key_sym].is_a?(Hash)
                  #go deeper
                  current_includes = current_includes[:include][key_sym]
                  current_context = klass_context(current_context[:associations][key])
                elsif current_context[:attachments].include?(key)
                  current_includes[:include][key_sym] = Dynamic::Base.active_storage_includes
                  break
                else
                  current_includes[:include].delete(key_sym)
                  break
                end
              end
            end

            includes
          end
        end
      end; include Serialization

      # created on backend Dynamic::MailHosting::Feature.create_default_associations
      module DefaultAssociation; extend ActiveSupport::Concern

        class_methods do

          def default_cci_association_name
            :default_cci
          end

          def default_cc_association_name
            :default_cc
          end

          def default_recipient_association_name
            :default_recipient
          end
        end
      end; include DefaultAssociation

      module Message
        extend ActiveSupport::Concern

        class_methods do
          def menu_items(record)
            proc do
              A(href: '#', class: 'dropdown-item') do
                I18n.t('crm.mailhosting.message.open')
              end.on(:click) do |event|
                event.prevent_default
                Crm::MailEditor.open_for_viewing(record)
              end
            end
          end
        end

      end

      module Email; extend ActiveSupport::Concern
      end
    end

  end
end
