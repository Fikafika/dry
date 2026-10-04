module Dynamic
  module Record
    class Base < ::Dynamic::Base

      class << self

        def member_params_key
          'base'
        end

        def api_path
          @api_path ||= [api_prefix, 'd', self.parent.name.demodulize.underscore, self.model_name.route_key].join('/')
        end

        def model_name # TODO it would use less memory if were computed for current I18n.locale instead of all available_locales
          @model_names[I18n.locale]
        end

        def define_model_name(translations = [], route_key)
          @model_names ||= {}
          translations_per_locale = nil
          fallbacks = nil

          I18n.available_locales.each do |l|
            next if @model_names[l]

            unless translations_per_locale
              fallbacks = {'fr' => 'en', 'en' => 'fr'}
              translations_per_locale = {}
              translations&.each do |t|
                translations_per_locale[t.locale] = t
              end
            end

            human_name = translations_per_locale[l].try(:human_name)
            human_name = translations_per_locale[fallbacks[l]].try(:human_name) unless human_name
            human_name = self.name.demodulize.classify unless human_name.present?

            plural_human_name = translations_per_locale[l].try(:plural_human_name)
            plural_human_name = translations_per_locale[fallbacks[l]].try(:plural_human_name) unless plural_human_name
            plural_human_name = human_name unless plural_human_name.present?

            gender = translations_per_locale[l].try(:gender) || 'm'

            @model_names[l] = ModelName.new(
              human_name: human_name,
              plural_human_name: plural_human_name,
              route_key: route_key,
              gender: gender,
            )
          end
        end

        def reflect_on_association_from_method_name(method_name) # convenient method for cases where an has_many association is not pluralized
          if method_name.end_with?('_id')
            reflect_on_association(method_name.sub(/_id$/, ''))
          elsif method_name.end_with?('_ids')
            a = method_name.sub(/_ids$/, '')
            as = a.pluralize
            reflect_on_association(as) || reflect_on_association(a)
          else
            reflect_on_association(method_name)
          end
        end

        class ModelName
          attr_reader :route_key

          def initialize(**options)
            @human_name = options[:human_name]
            @plural_human_name = options[:plural_human_name]
            @route_key = options[:route_key]
          end

          def human(**options)
            if options[:count].nil? || options[:count] <= 1
              return @human_name
            else
              return @plural_human_name
            end
          end
        end

        attr_accessor :translations

        def attribute_translations(name, translations = [])
          @translations ||= {}
          translations.each do |t|
            @translations[name] ||= {}
            @translations[name][t.locale] ||= t.human_name
          end
        end

        def human_attribute_name(attr, options = {})
          return base_class.human_attribute_name(attr, options) if self != base_class
          locale = options[:locale] || I18n.locale
          if translations.try(:[], attr)&.any?
            result = translations.dig(attr, locale)
          else
            result = I18n.t("activerecord.defaults.attributes.#{attr}", locale: locale, default: false)
          end
          result = attr.to_s.gsub('_', ' ').capitalize unless result.present?
          return result
        end

        def human_attribute_value(attr, value, options)
          case self.attributes.dig(attr, :type) # TODO formatter could be prepared in self.attributes intead of a case/when
          when 'Boolean'
            case value
            when true, 'true', '1'
              I18n.t('shared._yes')
            when false, 'false', '0'
              I18n.t('shared._no')
            else
              value
            end
          when 'Enum'
            self.attributes.dig(attr, :mapping_invert, I18n.locale, value) || value
          else
            super(attr, value, options)
          end
        end

        def values_for_protocol(record_id, protocol, names)

          # produces {:name_1 => 1, :name_2 => 1, ...}
          includes_param = Hash[names.product([1])]

          self.includes(includes_param).find_without_cache(record_id) do |record|
            values = {};

            names.each do |name|
              values[name] = []
              record.send(name)&.each do |instance|
                instance.class.protocol_attributes(protocol).each do |attribute_name|
                  values[name] << instance.send(attribute_name)
                end
              end
            end

            yield(values)
          end
        end
      end

      def dynamic_associations
        self.class.parent.const_get(:DynamicAssociation).where(
          association_owner_type: self.class.name,
          association_owner_id: self.id,
        ).includes(association_target: 1)
      end

      def update_cache_after_destroy
        super
        self.class.parent.const_get(:DynamicAssociation).clear_cache
      end

      module Identification; extend ActiveSupport::Concern

        class_methods do

          def name_attribute # redefined in schema load
            @name_attribute ||= self.attribute_names.detect do |a|
              a == 'name'
            end || self.attribute_names.detect do |a|
              a =~ /\Aname\z|\Anom\z|\Atitle\z|\Aintitule\z|\Alibelle\z/
            end || self.attribute_names.detect do |a|
              a =~ /\Aname_.*|\Anom_.*|\Atitle_.*|\Aintitule_.*|\Alibelle_.*/
            end
          end

          def photo_attachment # redefined in schema load
            @photo_attachment ||= (self.reflect_on_all_attachments.detect do |a|
              a.macro == :has_one_attached && a.name =~ /\Aphoto\z|\Alogo\z/
            end || self.reflect_on_all_attachments.detect do |a|
              a.macro == :has_one_attached && a.name =~ /\Aphoto_.*|\Alogo_.*/
            end)&.name&.to_s
          end
        end

      end; include Identification

      module DataTable; extend ActiveSupport::Concern

        class_methods do

          def datatable_column_by_name
            return @datatable_column_by_name if @datatable_column_by_name
            return {} unless options_for_indexed_json.any?

            @datatable_column_by_name = {}

            root_klass = self

            travel_through_options_for_indexed_json do |klass, attr, assoc, attachment, path, options|
              if attr
                column_klass = ::Crm::Datatable::Column.klass_from_method_name(klass, attr)
                name = (path + [attr]).join('.')

                @datatable_column_by_name[name] = column_klass&.new({
                  name: name,
                  klass: klass,
                  method_name: attr,
                  root_klass: root_klass,
                  depth: path.length + 1,
                  panel_side: 'right',
                })
              end
              a = assoc || attachment
              if a
                column_klass = ::Crm::Datatable::Column.klass_from_method_name(klass, a.name)
                name = path.join('.')

                @datatable_column_by_name[name] = column_klass&.new({
                  name: name,
                  klass: klass,
                  method_name: a.name,
                  root_klass: root_klass,
                  depth: path.length + 1,
                  panel_side: 'right',
                })
              end
              [] # return nothing
            end

            return @datatable_column_by_name
          end

          def options_for_indexed_json
            return self.base_class.options_for_indexed_json if self != self.base_class
            @options_for_indexed_json ||= OptionsForIndexedJson.new(self).load
          end

          class OptionsForIndexedJson # options_for_indexed_json can be too big so we load it asynchronously
            include Hyperstack::State::Observable

            attr_accessor :value
            attr_accessor :klass

            delegate :each, :each_with_index, :[], :any?, to: :@value

            def initialize(klass)
              @value = {}
              @klass = klass
              @loaded = false
            end

            def load
              @schema_klass ||= ::Dynamic::Schema::Klass.includes(
                only: [:id, :name], # TODO .select(*['id', 'name'])
                include: {options_for_indexed_json_for_current_user: 1}
              ).where(name: klass.name.demodulize, schema_id: klass.parent.name.demodulize.underscore).first do |schema_klass|
                @value = schema_klass.options_for_indexed_json_for_current_user || {}
                @loaded = true
                mutate
              end
              return self
            end

            def loaded?
              @loaded
            end
          end

          def travel_through_options_for_indexed_json(klass = self, path = [], options_for_indexed_json = self.options_for_indexed_json, &block)
            return [] if !klass || !options_for_indexed_json&.any?

            result = []

            klass.attribute_and_attachment_names_from_options_for_indexed_json(options_for_indexed_json).each do |attr|
              result.concat(yield(klass, attr, nil, nil, path, {}))
            end
            sort_by_human_name(options_for_indexed_json['include'])&.each do |method_name, o|
              assoc = klass.reflect_on_association(method_name)
              next unless assoc
              assoc_name = assoc.collection? ? assoc.name + '[]' : assoc.name
              p = path + [assoc_name]
              result.concat(yield(klass, nil, assoc, nil, p, o))
              result.concat(travel_through_options_for_indexed_json(assoc.klass, p, o, &block))
            end
            return result
          end

          def attribute_and_attachment_names_from_options_for_indexed_json(options_for_indexed_json = self.options_for_indexed_json)
            self.reflect_on_all_attachments # why reflect_on_attachment doesn't work without reflect_on_all_attachments ? ?

            a = (options_for_indexed_json['only']&.compact&.select{|attr| self.attributes[attr] || self.indexable_virtual_attributes[attr]} || []) +\
              (options_for_indexed_json['include']&.keys&.select{|a| self.reflect_on_attachment(a) } || [])

            if !a.include?('type') && subclasses.any?
              a << 'type'
            end

            return sort_by_human_name(a)
          end

          def sort_by_human_name(attributes)
            return attributes&.sort_by{|attr| self.human_attribute_name(attr).downcase}
          end

          def datatable_column_names
            return @datatable_column_names if @datatable_column_names
            @datatable_column_names = []
            travel_through_options_for_indexed_json do |klass, attr, assoc, attachment, path, _|
              if assoc
                @datatable_column_names << path.join('.')
              elsif attr
                @datatable_column_names << (path + [attr]).join('.')
              elsif attachment
                @datatable_column_names << (path + [attachment.name]).join('.')
              end
            end
            return @datatable_column_names
          end

        end

        included do
          scope :where_filters, rison: true
          scope :where_query, rison: true
          scope :join_positions
        end

      end; include DataTable

    end

    class Association < ::Dynamic::Base
      def self.api_path
        return @api_path if @api_path
        schema_name = self.class.name == 'Dynamic::Record::Association' ? ':schema_name' : parent.name.demodulize.underscore
        @api_path = [api_prefix, 'd', schema_name, 'dynamic_associations'].join('/')
        return @api_path
      end

      belongs_to :association_owner
      belongs_to :association_target

      scope :where_filters
      scope :for_schema_associations

      def destroy(options = {}, &block)
        w = options[:where]&.deep_dup || {}
        w.merge!({
          association_owner_type: self.association_owner_type,
          association_owner_id: self.association_owner_id,
        })
        super(options.merge(where: w), &block)
      end
    end

    class Version < ::Dynamic::Base
      def self.api_path
        @api_path ||= [api_prefix, 'd', schema_name, self.name.gsub(/Version$/, '').constantize.model_name.route_key, ':item_id', 'versions'].join('/')
      end

      enum event: [:create, :update, :destroy]

      belongs_to :author, class_name: 'User'
      belongs_to :source, polymorphic: true
    end

  end
end

