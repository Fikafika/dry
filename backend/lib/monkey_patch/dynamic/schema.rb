# frozen_string_literal: true

require 'dynamic/cnam/ine'
require 'dynamic/cnam/siscol'
require 'dynamic/cnam/export'
require 'dynamic/permission/feature'
require 'uneek_formatting/dynamic/schema'

ActiveSupport.on_load(:dynamic_schema) do

  concerning :CreateFeatures do
    included do

      after_create :create_features

      FEATURES = {
        'Dynamic::Menu::Feature' => { dependency_order: 40 }, # Need by Dynamic::Dashboard
        'Dynamic::Notification::Feature' => {},
        'Dynamic::Formula::Feature' => { dependency_order: 20 },
        'Dynamic::Elasticsearch::Feature' => { dependency_order: 55 }, # dependent of OpenSearch
        'Dynamic::Workflow::Feature' => { dependency_order: 70 },
        'Dynamic::Dashboard::Feature' =>  { dependency_order: 56 },  # dependent from Dynamic::Elasticsearch::Feature, Dynamic::Menu::Item
        'Dynamic::Query::Feature' => { dependency_order: 57 }, # dependent of OpenSearch
        'Dynamic::DocGen::Feature' => { dependency_order: 60 },
        'Dynamic::Api::AddressSearchEngine::Feature' => {},
        'Dynamic::Cnam::Ine::Feature' => {},
        'Dynamic::Cnam::Siscol::Feature' => {},
        'Dynamic::Cnam::Export::Feature' => {},
        'Dynamic::MailHosting::Feature' => { dependency_order: 80 },
        'Dynamic::Vcard::Feature' => {},
        'Dynamic::Sms::Feature' => {},
        'Dynamic::Merge::Feature' => {},
        'Dynamic::Copy::Feature' => {},
        'Dynamic::Export::Feature' => {},
        'Dynamic::Kanban::Feature' => {},
        'Dynamic::RecipientInfo::Feature' => {},
        'Dynamic::Knewsletter::Feature' => {},
        'Dynamic::Communication::Feature' => {},
        'Dynamic::Event::Feature' => {},
        'Dynamic::Country::Feature' => {},
        'Dynamic::Timezone::Feature' => {},
        'Dynamic::PhoneData::Feature' => {},
        'Dynamic::Currency::Feature' => {},
        'Dynamic::Datatable::Style::Feature' => {},
        'Dynamic::Period::Feature' => {},
        'Dynamic::Permission::Feature' => { dependency_order: 80 },
        'Dynamic::Product::Feature' => {},
        'Dynamic::Amount::Feature' => {},
        'Dynamic::DocumentManagement::Feature' => {},
        'Dynamic::Experience::Feature' => {},
        'Dynamic::Transaction::Feature' => {},
        'Dynamic::Company::Feature' => {},
        'Dynamic::Contact::Feature' => {},
        'Dynamic::Position::Feature' => {},
      }.deep_freeze

      def create_features
        features_attrs = []
        FEATURES.each do |feature_name, base_attrs|
          feature_module = feature_name.safe_constantize
          if feature_module
            next unless feature_module.respond_to?(:feature_attributes)
            attrs = feature_module.feature_attributes
            attrs.merge!(base_attrs)
            attrs.merge!(name: feature_name)
            features_attrs.concat([attrs])
          else
            Rails.logger.warn("skip create feature #{feature_name}: unknown module")
          end
        end

        self.features.create(features_attrs)

        FEATURES.each do |feature_name, base_attrs|
          feature_module = feature_name.safe_constantize
          next unless feature_module&.respond_to?(:after_schema_create)
          feature_module.after_schema_create(self, base_attrs.merge(name: feature_name))
        end
      end

    end
  end

  concerning :Redirections do
    included do
      has_many :redirections, class_name: 'Dynamic::Redirection', inverse_of: :schema
      accepts_nested_attributes_for :redirections, allow_destroy: true
    end
  end

  concerning :Themes do
    included do
      has_many :themes, class_name: 'Dynamic::Theme', inverse_of: :schema
      accepts_nested_attributes_for :themes, allow_destroy: true
    end
  end

  concerning :UpdateDynamicMenu do
    included do

      after_update :update_dynamic_menus_update_items, if: :update_menu_items?

      attr_accessor :update_menu_items
      def update_menu_items?
        self.name_previously_changed? && (@update_menu_items != false)
      end
    end

    def update_dynamic_menus_update_items
      old_name =self.previous_changes['name']&.first
      new_name = self.name
      return unless old_name.present? && new_name.present?

      table_name = "d_#{self.permalink.gsub('-', '_')}_r_menu_items"
      table = Arel::Table.new(table_name)
      wheres = table['link'].matches("/%/#{old_name.underscore}/%")
      set = Arel.sql(%Q[link = REGEXP_REPLACE(link, '\/(.*)\/#{old_name.underscore}\/', '/\\1/#{new_name.underscore}/')])

      u = Arel::UpdateManager.new
      u.table(table)
      u.wheres = table.where(wheres).constraints
      u.set set

      self.class.connection.update(u)
    end

  end

  concerning :Export do

    class_methods do

      def only_for_export(export_options = {})
        ['id', 'name', 'permalink', 'comment']
      end

      def includes_for_export(export_options = {})
        result = {
          except: export_include_exceptions(self),
          translations: {as: :translations_attributes, except: ['schema_id']},
          klasses: {
            as: :klasses_attributes,
            except: export_include_exceptions(Dynamic::Schema::Klass) + ['elasticsearch_mapping', 'elasticsearch_updated_at', 'dependencies_from_formulas'],
            include: {
              translations: {as: :translations_attributes, except: ['schema_id', 'dynamic_schema_klass_id']},
              attrs: {
                as: :attrs_attributes,
                except: export_include_exceptions(Dynamic::Schema::Attribute::Base),
                include: {
                  translations: {as: :translations_attributes, except: ['schema_id', 'dynamic_schema_attribute_id']},
                  values: {
                    as: :values_attributes,
                    except: export_include_exceptions(Dynamic::Schema::Attribute::Enum::Value),
                    include: {
                      translations: {as: :translations_attributes, except: ['schema_id', 'dynamic_schema_attribute_enum_value_id']},
                    }
                  },
                },
              },
              associations: {
                as: :associations_attributes,
                except: export_include_exceptions(Dynamic::Schema::Association::Base),
                include: {
                  translations: {as: :translations_attributes, except: ['schema_id', 'dynamic_schema_association_id']},
                },
              },
              attachments: {
                as: :attachments_attributes,
                except: export_include_exceptions(Dynamic::Schema::Attachment::Base),
                include: {
                  translations: {as: :translations_attributes, except: ['schema_id', 'dynamic_schema_attachment_id']},
                },
              },
              validations: {
                as: :validations_attributes,
                except: export_include_exceptions(Dynamic::Schema::Validation::Base),
                include: {
                  translations: {as: :translations_attributes, except: ['schema_id', 'dynamic_schema_validation_id']},
                  attr_ids: {},
                },
              },
            },
          }
        }

        if export_options[:layouts].in?(['1', true])
          result[:klasses][:include][:skip_create_default_layouts] = {overriden_value: true}
          result[:layouts] = Dynamic::Layout.includes_for_export(export_options).merge(as: :layouts_attributes)
        end

        if export_options[:forms].in?(['1', true])
          result[:klasses][:include][:skip_create_default_forms] = {overriden_value: true}
          result[:forms] = Dynamic::Form.includes_for_export(export_options).merge(as: :forms_attributes)
          result[:records_for_forms] = {as: :records_for_forms_attributes}
        end

        return result
      end

      def export_include_exceptions(klass = nil)
        r = ['created_at', 'updated_at', 'deleted_at']
        r += ['schema_id'] unless klass == self
        return r unless klass
        return r +
          klass.translated_attribute_names.map(&:to_s) +
          klass.globalize_attribute_names.map(&:to_s)
      end

    end

  end

  concerning :Maintenance do

    class Dynamic::Schema
      def drop_all_data(do_it = false)
        unless do_it
          puts "run drop_all_data(true) in order to:"
        end

        table_prefix = "#{Dynamic::ROOT_NAME.underscore}_#{self.name.underscore}_"
        other_schemas_with_same_start = Dynamic::Schema.where('name LIKE ?', "#{self.name}%").where.not(id: self.id).all
        table_prefix_exceptions = ["#{table_prefix}#{RESERVED_CONSTANT.underscore}_"] + other_schemas_with_same_start.map{|t| "#{Dynamic::ROOT_NAME.underscore}_#{t.name.underscore}_"}

        tables = []
        ActiveRecord::Base.connection.tables.each do |t|
          tables << t if t.start_with?(table_prefix) && !table_prefix_exceptions.detect{|p| t.start_with?(p) }
        end

        if do_it
          ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{tables.join(', ')} CASCADE")
        else
          puts "drop following tables: #{tables.join(', ')}"
        end

        if do_it
          ActiveStorage::Blob.unattached.find_each do |b|
            b.purge
          end
        else
          puts "drop #{ActiveStorage::Blob.unattached.count} unattached blogs"
        end

        ::OpenSearch::Model.refresh


        index_prefixes = [
          "#{Dynamic::ROOT_NAME.underscore}-#{self.name.underscore}-",
          "#{Dynamic::ROOT_NAME.underscore}-#{self.name.underscore.gsub('_', '-')}-",
        ]

        index_prefix_exceptions = other_schemas_with_same_start.map do |t|
          "#{Dynamic::ROOT_NAME.underscore}-#{t.name.underscore}-"
        end + other_schemas_with_same_start.map do |t|
          "#{Dynamic::ROOT_NAME.underscore}-#{t.name.underscore}".gsub('_', '-')
        end + index_prefixes.map do |p|
          "#{p}#{RESERVED_CONSTANT.underscore}-"
        end

        indices = ::OpenSearch::Model.client.indices.get(index: '_all').keys.select do |i|
          index_prefixes.detect{|p| i.start_with?(p)} && !index_prefix_exceptions.detect{|p| i.start_with?(p) }
        end

        if do_it
          indices.each{ |i| ::OpenSearch::Model.client.indices.delete(index: i) }
        else
          puts "delete following opensearch indices: #{indices.join(', ')}"
        end

        if do_it
          self.reload
          self.unload
          self.klasses.map{|k| k.send(:create_table) }
          self.load # for recreate tables
          ::OpenSearch::Model.refresh
          self.klasses.each{|k| k.update_elasticsearch_index(true)} #
        end

        if do_it
          self.create_association_table
          self.klasses.each{|k| k.send(:create_version_table)}
          self.klasses.each{|k| k.send(:create_translation_table)}
        end
      end
    end

  end

  concerning :Logs do

    private

    if ENV['DISABLE_SCHEMA_LOGGING'] != 'true' && !Rails.env.test?
      def load!(options)
        start_at = Time.now
        Rails.logger.info "Start load schema #{self.name} at #{start_at.inspect} (pid: #{Process.pid}, thread: #{Thread.current.object_id}, object_id: #{self.object_id}, updated_at: #{self.updated_at.inspect})"
        super
      ensure
        finish_at = Time.now
        Rails.logger.info "Finish load schema #{self.name} at #{finish_at.inspect} (#{sprintf('%.3f', finish_at.to_f - start_at.to_f)} seconds)"
      end
    end

  end

  include HyperResourceBroadcastUpdate

end
