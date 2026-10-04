module Dynamic
  class Schema < Base

    translates :human_name
    globalize_accessors

    has_many :klasses, class_name: 'Dynamic::Schema::Klass', inverse_of: :schema
    has_many :features, class_name: 'Dynamic::Schema::Feature', inverse_of: :schema
    has_many :migrations, class_name: 'Dynamic::Schema::Migration', inverse_of: :schema
    has_many :layouts, class_name: 'Dynamic::Layout', inverse_of: :schema
    has_many :forms, class_name: 'Dynamic::Form', inverse_of: :schema
    has_many :themes, class_name: 'Dynamic::Theme', inverse_of: :schema
    has_many :import_settings, class_name: 'Dynamic::Import::Setting', inverse_of: :schema
    has_many :jobs, class_name: 'Dynamic::Import::Job', inverse_of: :schema
    has_many :redirections, class_name: 'Dynamic::Redirection', inverse_of: :schema

    ROOT_NAME = 'D'

    @@schema_by_schema_name = {}

    def initialize(json = HashWithIndifferentAccess.new, association_scope = nil)
      @mutate_enabled = true
      super
    end

    class << self

      def load(schema_name, &block)
        result = (
          @@schema_by_schema_name[schema_name] ||= begin
            s = includes(includes_for_load).find(schema_name&.classify_permalink) do |schema|
              if schema.name
                if schema.must_load_constants?
                  schema.load_constants
                end
                yield(schema) if block_given?
              end
            end
            unless s.constants_loaded?
              s.mutate_after_constants_loaded
            end
            s
          end
        )

        result.reload(&block) if result.stale

        return result
      end

      INCLUDES_FOR_LOAD = {
        translations: { except: ['schema_id'] },
        klasses: {
          except: [
            'elasticsearch_mapping',
            'elasticsearch_updated_at',
            'options_for_indexed_json',
            'dependencies_from_formulas',
            'permalink',
            'created_at',
            'updated_at',
            'const_table_name',
            'original_const_table_name',
            'schema_id',
          ],
          include: {
            translations: { except: ['schema_id', 'dynamic_schema_klass_id'] },
            attrs: {
              except: [
                'created_at',
                'updated_at',
                'schema_id',
              ],
              include: {
                translations: { except: ['schema_id', 'dynamic_schema_attribute_id'] },
                values: {
                  include: {
                    translations: 1,
                  }
                },
              },
            },
            associations: {
              except: [
                'created_at',
                'updated_at',
                'schema_id',
              ],
              include: {
                translations: { except: ['schema_id', 'dynamic_schema_association_id'] },
              },
            },
            attachments: {
              except: [
                'created_at',
                'updated_at',
                'schema_id',
              ],
              include: {
                translations: { except: ['schema_id', 'dynamic_schema_attachment_id'] },
                variants: {
                  except: [
                    'created_at',
                    'updated_at',
                    'schema_id',
                  ]
                },
              },
            },
          },
        },
        features: {
          except: [
            'created_at',
            'updated_at',
            'schema_id',
          ],
          include: {
            translations: { except: ['schema_id', 'dynamic_schema_feature_id'] },
            options: { include: { translations: { except: ['schema_id', 'dynamic_schema_option_id'] } } },
            concerns: {
              include: {
                options: { include: { translations: { except: ['schema_id', 'dynamic_schema_option_id'] } } } ,
                klass: { include: { schema: {only: [:name] } } },
              },
            },
          },
        },
      }

      def includes_for_load
        INCLUDES_FOR_LOAD
      end

      def api_id(resource)
        to_permalink(resource.name) || resource.id.to_s
      end

      def has_api_id?(resource, resource_id)
        (resource.name && (to_permalink(resource.name) == resource_id)) || (resource.id.to_s == resource_id)
      end

    end

    def must_load_constants?
      (!constants_loaded? && !constants_loading?) || !!stale?
    end

    attr_writer :constants_loaded

    def constants_loaded?
      @constants_loaded
    end

    attr_writer :constants_loading

    def constants_loading?
      @constants_loading
    end

    attr_reader :promise_of_load_constants

    def mutate_after_constants_loaded
      disable_mutate
      new_promise_of_load_constants.then do
        enable_mutate
        mutate
      end
    end

    def new_promise_of_load_constants
      self.instance_variable_set(:@promise_of_load_constants, Promise.new)
    end

    def enable_mutate
      @mutate_enabled = true
    end

    def disable_mutate
      @mutate_enabled = false
    end

    def mutate
      return if mutate_disabled?
      super
    end

    def mutate_disabled?
      !@mutate_enabled
    end

    def load_constants
      return unless loaded?

      constants_loading do
        const
        const_assoc_klass
        const_include_modules
        klasses_preloaded.each(&:load_constants)
        features_order_by_dependency.each(&:load_constants)
        define_enabled_features
      end
    end

    def constants_loading
      @constants_loading = true
      yield
      @constants_loading = false
      self.constants_loaded = true
      if self.promise_of_load_constants && !self.promise_of_load_constants.resolved?
        self.promise_of_load_constants&.resolve
      end
    end

    def after_constants_loaded
      promise = self.promise_of_load_constants
      if promise && !promise.resolved?
        promise.then do
          yield
        end
      end
    end

    def reload
      unload_constants if constants_loaded?
      super do
        if must_load_constants?
          load_constants
         end
         if block_given?
           mutate
           yield(self)
         end
      end
    end

    def unload_constants
      self.constants_loaded = false
      features_order_by_dependency.each(&:unload_constants)

      self.class.reflections.each do |k, v|
        next unless v.collection?
        v.klass.try(:unload_constants)
      end

      recursive_remove_const(const)

      @const = nil
      @const_klasses = nil
      @reserved = nil

      @klasses_by_id = nil
      @klasses_by_const_absolute_name = nil
      @associations_by_id = nil
      @attr_or_assoc_or_attach_by_id = nil
      @attr_or_assoc_or_attach_or_klass_by_id = nil

      @name_attribute = nil
      @photo_attachment = nil

      Dynamic::Form.clear_cache # should we create a Dynamic::Form::Feature with a unload_constants method ?
    end

    def self.unload_all
      @@schema_by_schema_name.clear
      cache['find'].values.each do |s|
        next unless s.constants_loaded?
        s.unload_constants
      end
    end

    def const
      return @const if @const

      if root.constants.include?(self.name.to_sym)
        result = root.const_get(self.name)
      else
        result = Module.new
        root.const_set(self.name, result)
      end

      @const = result
      return @const
    end

    def const_dynamic_record
      return const.const_get('DynamicRecord', false) if const.const_defined?('DynamicRecord', false)

      result = Class.new(Dynamic::Record::Base) # abstract
      const.const_set('DynamicRecord', result)

      return result
    end

    def const_klasses
      return [] unless self.constants_loaded?
      @const_klasses ||= self.klasses.sort_by(&:id).map(&:const)
    end

    def const_include_modules
      [
        Routes,
        ConstGetByRouteKey,
      ].each do |m|
        next if const < m
        const.include(m)
      end
    end

    def root
      Object.const_defined?(ROOT_NAME) ? Object.const_get(ROOT_NAME) : Object.const_set(ROOT_NAME, Module.new)
    end

    def klasses_preloaded
      result = self.klasses.sort_by{|k| k.depth} # why sort_by(&:depth) doesn't work properly ?
      result.each do |klass|
        if klass.superklass_id
          klass.superklass = klasses_by_id[klass.superklass_id]
          if klass.superklass
            klass.superklass.subklasses << klass
          end
        end
        klass.baseklass = klasses_by_id[klass.baseklass_id] if klass.baseklass_id
        klass.associations.each do |a| #TODO
          a.owner_klass = klasses_by_id[a.owner_klass_id]
          a.target_klass = klasses_by_id[a.target_klass_id]
          a.schema = klass.schema
        end
      end
      return result
    end

    def klasses_by_id
      return @klasses_by_id if @klasses_by_id
      return {} unless self.loaded?
      @klasses_by_id = {}
      self.klasses.each do |klass|
        @klasses_by_id[klass.id] = klass
      end
      return @klasses_by_id
    end

    def klasses_by_const_absolute_name
      return @klasses_by_const_absolute_name if @klasses_by_const_absolute_name
      return {} unless self.loaded?
      @klasses_by_const_absolute_name = {}
      self.klasses.each do |klass|
        @klasses_by_const_absolute_name[klass.const_absolute_name] = klass
      end
      return @klasses_by_const_absolute_name
    end

    def attr_or_assoc_or_attach_by_id
      return @attr_or_assoc_or_attach_by_id if @attr_or_assoc_or_attach_by_id
      return {} unless self.loaded?
      @attr_or_assoc_or_attach_by_id = {}
      self.klasses.each do |klass|
        klass.attrs.each do |a|
          @attr_or_assoc_or_attach_by_id[a.id] = a
        end
        klass.associations.each do |a|
          @attr_or_assoc_or_attach_by_id[a.id] = a
        end
        klass.attachments.each do |a|
          @attr_or_assoc_or_attach_by_id[a.id] = a
        end
      end
      return @attr_or_assoc_or_attach_by_id
    end

    def attr_or_assoc_or_attach_or_klass_by_id
      @attr_or_assoc_or_attach_or_klass_by_id ||= attr_or_assoc_or_attach_by_id.merge(klasses_by_id)
    end

    def associations
      associations_by_id.values
    end

    def associations_by_id
      return {} unless loaded?
      return @associations_by_id if @associations_by_id
      @associations_by_id ||= {}
      klasses.each do |k|
        k.associations.each do |a|
          @associations_by_id[a.id] = a
        end
      end
      return @associations_by_id
    end

    def features_order_by_dependency
      features&.select{|f| f.enabled }&.sort_by{|f| f.dependency_order || 0} || []
    end

    def has_feature_enabled?(feature)
      features&.detect{|f| f.enabled && f.name == feature}.present? rescue false
    end

    def const_assoc_klass
      return const.const_get('DynamicAssociation') if const.const_defined?('DynamicAssociation')
      const.const_set('DynamicAssociation', Class.new(Dynamic::Record::Association))
      return result
    end

    def define_enabled_features
      enabled_features = Set.new
      features&.each do |f|
        enabled_features << f.name if f.enabled
      end
      const.define_singleton_method(:feature_enabled?) do |name|
        enabled_features.include?(name)
      end
    end

    def recursive_remove_const(constant)
      return unless constant
      constant.constants.each do |c|
        s = constant.const_get(c)
        if s.is_a?(Module) && s.parent == constant
          recursive_remove_const(s)
        end
      end
      constant.parent.remove_const(constant.name.demodulize)
    end

    def self.stale_all_records(data)
      return if data && data['updated_at'] == @previous_updated_at
      @previous_updated_at = data['updated_at']
      self.cache.values.each do |a|
        a.values.each do |record|
          next unless record.class == self
          record.stale! if record.id == data['id'] || record.name == data['name']
        end
      end
    end

    module Routes; extend ActiveSupport::Concern

      class_methods do
        def search_path(parameters = {})
          ::HyperResource::Base.interpolate_path_and_add_parameters("#{ENV['APP_PATH_PREFIX']}/api/search/#{self.name.underscore}.json", parameters)
        end
      end

    end

    module ConstGetByRouteKey; extend ActiveSupport::Concern

      class_methods do
        attr_accessor :const_klasses_by_route_key

        def const_get_by_route_key(key)
          return @const_klasses_by_route_key[key] if @const_klasses_by_route_key # filled in Klass.load_route_key
        end
      end

    end

    module Reserved; extend ActiveSupport::Concern

      RESERVED_CONSTANT = 'R'

      def const_reserved_klass(klass_name, super_klass, options = {}, &block) # e.g Workflow::ManualTrigger => D::Uneek::R::Workflow:ManualTrigger
        absolute_klass_name = absolute_reserved_klass_name(klass_name)
        result = absolute_klass_name&.safe_constantize

        return result if result && result.name == absolute_klass_name

        p = reserved

        a = klass_name.split('::')
        k = a.pop
        a.each do |m|
          unless p.constants.include?(m.to_sym)
            p.const_set(m, Module.new)
          end
          p = p.const_get(m)
        end

        if p.constants.include?(k.to_sym) && (RUBY_ENGINE == 'opal' ? (p.const_get(k).parent == p) : (p.const_get(k).module_parent == p))
          result = p.const_get(k)
        else
          result = Class.new(super_klass)
          result.singleton_class.define_method :i18n_key do
            super_klass.i18n_key
          end
          p.const_set(k, result)
          yield result if block_given?
        end

        return result
      end

      def absolute_reserved_klass_name(klass_name)
        return "#{const.name}::#{RESERVED_CONSTANT}::#{klass_name}"
      end

      def reserved
        return @reserved if @reserved
        if const.constants.include?(RESERVED_CONSTANT.to_sym)
          @reserved = const.const_get(RESERVED_CONSTANT)
        else
          @reserved = Module.new
          const.const_set(RESERVED_CONSTANT, @reserved)
        end
        return @reserved
      end

    end; include Reserved


    class Base < ::Dynamic::Base

      class << self

        def api_path
          return @api_path if @api_path
          k = (self.name.end_with?('::Base')) ? parent : self
          parent = k.parent.respond_to?(:api_path) ? k.parent : k.parent.parent
          @api_path = [parent.api_path, ":#{parent.name.demodulize.underscore}_id", k.name.demodulize.pluralize.underscore].join('/')
          return @api_path
        end

        def api_id(resource)
          to_permalink(resource.name) || resource.id.to_s
        end

        def has_api_id?(resource, resource_id)
          # super makes everything fail
          (resource.name && (to_permalink(resource.name) == resource_id)) || (resource.id.to_s == resource_id)
        end

        def unload_constants
          clear_cache
          reflections.each do |k, v|
            next unless v.collection?
            v.klass.try(:unload_constants)
          end
        end

      end

    end

    class Klass < Base
      member_action :reindex, http_method: :post

      translates [:human_name, :plural_human_name]
      globalize_accessors

      belongs_to :schema, class_name: 'Dynamic::Schema', inverse_of: :klasses
      has_many :attrs, class_name: 'Dynamic::Schema::Attribute::Base', inverse_of: :klass
      has_many :associations, class_name: 'Dynamic::Schema::Association::Base', inverse_of: :owner_klass
      has_many :attachments, class_name: 'Dynamic::Schema::Attachment::Base', inverse_of: :owner_klass
      has_many :cascades, class_name: 'Dynamic::Schema::Cascade::Base', inverse_of: :klass
      has_many :normalizations, class_name: 'Dynamic::Schema::Normalization::Base', inverse_of: :klass

      belongs_to :name_attribute, class_name: 'Dynamic::Schema::Attribute::String'
      belongs_to :photo_attachment, class_name: 'Dynamic::Schema::Attachment::HasOne'

      belongs_to :superklass, class_name: 'Dynamic::Schema::Klass'
      attr_accessor :baseklass # should be an association ?

      enum table_profile: [:small, :medium, :large, :huge]

      TABLE_PROFILE = { # profiles must be the same as in dynamic_record gem
        small: {
          'String': {
            count: 8,
            indexed: 2,
          },
          'Text': {
            count: 4,
            indexed: 1,
          },
          'Integer': {
            count: 16,
            indexed: 1,
          },
          'Float': {
            count: 8,
            indexed: 1,
          },
          'Boolean': {
            count: 8,
            indexed: 1,
          },
          'DateTime': {
            count: 2,
            indexed: 1,
          },
          'Uuid': {
            count: 8,
            indexed: 1,
          },
        },
        medium: {
          'String': {
            count: 24,
            indexed: 6,
          },
          'Text': {
            count: 12,
            indexed: 4,
          },
          'Integer': {
            count: 32,
            indexed: 4,
          },
          'Float': {
            count: 16,
            indexed: 4,
          },
          'Boolean': {
            count: 12,
            indexed: 2,
          },
          'DateTime': {
            count: 4,
            indexed: 2,
          },
          'Uuid': {
            count: 16,
            indexed: 4,
          },
        },
        large: {
          'String': {
            count: 48,
            indexed: 6,
          },
          'Text': {
            count: 24,
            indexed: 4,
          },
          'Integer': {
            count: 64,
            indexed: 4,
          },
          'Float': {
            count: 32,
            indexed: 4,
          },
          'Boolean': {
            count: 24,
            indexed: 2,
          },
          'DateTime': {
            count: 16,
            indexed: 2,
          },
          'Uuid': {
            count: 32,
            indexed: 4,
          },
        },
        huge: {
          'String': {
            count: 128,
            indexed: 6,
          },
          'Text': {
            count: 64,
            indexed: 4,
          },
          'Integer': {
            count: 256,
            indexed: 4,
          },
          'Float': {
            count: 128,
            indexed: 4,
          },
          'Boolean': {
            count: 256,
            indexed: 2,
          },
          'DateTime': {
            count: 64,
            indexed: 2,
          },
          'Uuid': {
            count: 128,
            indexed: 4,
          },
        },
      }.with_indifferent_access

      def load_constants
        const
        load_versioning
        load_attributes
        load_associations
        load_attachments
        load_route_key
        return @const
      end

      def const
        return @const if @const

        if schema.const.constants.include?(name.to_sym)
          @const = schema.const.const_get(name)
          return @const
        end

        if superklass_id
          result = Class.new(schema.const.const_get(superklass.name))
          b = schema.klasses_by_id[self.baseklass_id].const
          result.define_singleton_method(:base_class) do
            b
          end
        else
          result = Class.new(schema.const_dynamic_record)
          result.define_singleton_method(:base_class) do
            result
          end
        end

        # TODO dynamic_associations

        schema.const.const_set(name, result)

        result.define_model_name(translations, route_key)

        @const = result
        return @const
      end

      def const_absolute_name
        "#{ROOT_NAME}::#{schema.name}::#{self.name}"
      end

      def name_attribute # overwrite belongs_to
        if association('name_attribute').loaded?
          return association('name_attribute').reader
        elsif self.name_attribute_id && association('attrs').loaded?
          return @name_attribute ||= self.attrs.detect{|a| a.id == self.name_attribute_id }
        end
        return nil
      end

      def photo_attachment # overwrite belongs_to
        if association('photo_attachment').loaded?
          return association('photo_attachment').reader
        elsif self.photo_attachment_id && association('attachments').loaded?
          return @photo_attachment ||= self.attachments.detect{|a| a.id == self.photo_attachment_id }
        end
        return nil
      end

      private

      def load_versioning
        return @const_version_klass if @const_version_klass

        v_name = "#{name}Version"

        if schema.const.constants.include?(v_name.to_sym)
          @const_version_klass = schema.const.const_get(v_name)
          return @const_version_klass
        end

        result = Class.new(::Dynamic::Record::Version)

        schema.const.const_set(v_name, result)

        @const_version_klass = result
        return @const_version_klass
      end

      def load_attributes
        self.attrs.each(&:load_constants)
        load_attribute_formats
        load_attribute_format_options
        load_attribute_types_for_format
        load_attribute_editors
        load_attribute_protocols
        load_timestamp_attributes
        load_identification_attributes
        load_indexed_types
      end

      def load_attribute_formats
        attribute_formats = inherited_attribute_formats
        const.define_singleton_method(:attribute_format) do |attr|
          attribute_formats[attr]
        end
      end

      def inherited_attribute_formats
        result = superklass&.inherited_attribute_formats&.dup || {}
        self.attrs.each do |a|
          next if a.format.blank?
          result[a.name] = a.format
        end
        return result
      end

      def load_attribute_editors
        attribute_editors = inherited_attribute_editors
        const.define_singleton_method(:attribute_editor) do |attr|
          attribute_editors[attr]
        end
      end

      def inherited_attribute_editors
        result = superklass&.inherited_attribute_editors&.dup || {}
        self.attrs.each do |a|
          next if a.editor.blank?
          result[a.name] = a.editor
        end
        return result
      end

      def load_attribute_format_options
        attribute_format_options = inherited_attribute_format_options
        const.define_singleton_method(:attribute_format_options) do |attr|
          attribute_format_options[attr] || {}
        end
      end

      def inherited_attribute_format_options
        result = superklass&.inherited_attribute_format_options&.dup || {}
        self.attrs.each do |a|
          next if a.format.blank? && a.format_options.blank?
          options = UneekFormatting::Dynamic::AttributeFormatter.default_options_for(a.type, a.format).merge(a.format_options || {})
          next if options.blank?
          result[a.name] = options
        end
        return result
      end

      def load_attribute_types_for_format
        attribute_types_for_format = inherited_attribute_types_for_format
        const.define_singleton_method(:attribute_type_for_format) do |attr|
          attribute_types_for_format[attr]
        end
      end

      def inherited_attribute_types_for_format
        result = superklass&.inherited_attribute_types_for_format&.dup || {}
        self.attrs.each do |a|
          next if a.format.blank? && a.format_options.blank?
          result[a.name] = a.type
        end
        return result
      end

      def load_attribute_protocols
        protocols_for_attributes = {}
        self.attrs.each do |r|
          protocols_for_attributes[r.name.to_sym] = r.protocols
        end
        const.define_singleton_method(:protocols_for_attributes) do
          protocols_for_attributes
        end

        const.define_singleton_method(:protocol_attributes) do |protocol|
          attributes = []
          protocols_for_attributes.each do |attr_name, protocols|
            attributes << attr_name if protocols.include?(protocol)
          end
          attributes
        end

      end

      def load_timestamp_attributes
        self.const.attribute('created_at', {type: 'DateTime'})
        self.const.attribute('updated_at', {type: 'DateTime'})
        self.const.attribute('deleted_at', {type: 'DateTime'})
      end

      def load_identification_attributes
        i = icon
        self.const.define_singleton_method :icon  do
          i
        end
        n = inherited_name_attribute&.name
        self.const.define_singleton_method :name_attribute do
          n
        end
        p = inherited_photo_attachment&.name
        self.const.define_singleton_method :photo_attachment do
          p
        end
      end

      def inherited_name_attribute
        name_attribute || superklass&.inherited_name_attribute
      end

      def inherited_photo_attachment
        photo_attachment || superklass&.inherited_photo_attachment
      end

      def load_indexed_types
        indexed_type_for_attributes = {}
        self.attrs.each do |r|
          indexed_type_for_attributes[r.name.to_sym] = r.class.indexed_type
        end
        indexed_type_for_attributes['id'] = 'string'
        indexed_type_for_attributes['created_at'] = 'date'
        indexed_type_for_attributes['updated_at'] = 'date'
        indexed_type_for_attributes['deleted_at'] = 'date'
        const.define_singleton_method(:indexed_type_for_attributes) do
          indexed_type_for_attributes
        end
      end

      def load_associations
        self.associations.each(&:load_constants)
      end

      def load_attachments
        self.attachments.each(&:load_constants)
      end

      def all_attrs_assocs_attachs
        return @all_attrs_assocs_attachs.values if @all_attrs_assocs_attachs
        return unless self.loaded?
        if self.baseklass && self.baseklass != self
          return self.baseklass.all_attrs_assocs_attachs
        end
        unless @all_attrs_assocs_attachs
          @all_attrs_assocs_attachs = {}
          compute_all_attrs_assocs_attachs_by_name(@all_attrs_assocs_attachs)
        end
        return @all_attrs_assocs_attachs.values
      end

      def compute_all_attrs_assocs_attachs_by_name(result = {})
        self.attrs.each{|a| result[a.name] = a }
        self.attachments.each{|a| result[a.name] = a }
        self.associations.each{|a| result[a.name] = a }
        self.subklasses.each do |s|
          s.compute_all_attrs_assocs_attachs_by_name(result)
        end
      end

      def attr_attachment_or_association(name)
        if self.baseklass && self.baseklass != self
          return self.baseklass.attr_attachment_or_association(name)
        end
        all_attrs_assocs_attachs
        return @all_attrs_assocs_attachs[name]
      end

      def subklasses
        @subklasses ||= [] # filled by klasses_preloaded
      end

      def load_route_key
        self.schema.const.const_klasses_by_route_key ||= {}
        self.schema.const.const_klasses_by_route_key[self.route_key] = self.const
      end
    end

    module Attribute
      class Base <::Dynamic::Schema::Base
        translates :human_name
        globalize_accessors

        belongs_to :klass, class_name: 'Dynamic::Schema::Klass', inverse_of: :attrs
        has_many :validations, class_name: 'Dynamic::Schema::Validation', inverse_of: :attr
        has_many :normalizations, class_name: 'Dynamic::Schema::Normalization::Base', inverse_of: :attr
        has_many :sequences, class_name: 'Dynamic::Schema::Sequence', inverse_of: :attr

        enum protocols: {http: 0, mailto: 1, tel: 2, sms: 3}

        enum format: { raw: 0 }

        enum editor: {}

        member_action :recompute_formula, http_method: :post

        class << self
          def api_path
            @api_path ||= [::Dynamic::Schema::Klass.api_path, ':klass_id', 'attributes'].join('/')
          end

          def subclasses
            @subclasses ||= [
              'Dynamic::Schema::Attribute::String',
              'Dynamic::Schema::Attribute::Text',
              'Dynamic::Schema::Attribute::Integer',
              'Dynamic::Schema::Attribute::Float',
              'Dynamic::Schema::Attribute::Boolean',
              'Dynamic::Schema::Attribute::Date',
              'Dynamic::Schema::Attribute::DateTime',
              'Dynamic::Schema::Attribute::TimeOfDay',
              'Dynamic::Schema::Attribute::TranslatableString',
              'Dynamic::Schema::Attribute::TranslatableText',
              'Dynamic::Schema::Attribute::Enum',
              'Dynamic::Schema::Attribute::Uuid',
            ].map(&:constantize)
          end
        end

        def load_constants
          options = {
            type: self.class.name.demodulize
          }
          if self.class.name == 'Dynamic::Schema::Attribute::Enum'
            options.merge!(enum_mapping)
            vs = values.map(&:name)
            klass.const.define_singleton_method self.name.pluralize do
              vs
            end
          end
          klass.const.attribute(self.name, options)
          klass.const.base_class.attribute_translations(self.name, self.translations) if self.translations
        end

        def enum_mapping
          result = {
            mapping: {},
            mapping_invert: {},
            possible_values: {},
          }

          available_locales = I18n.available_locales
          available_locales.each do |l|
            result[:mapping][l] = {}
            result[:mapping_invert][l] = {}
            result[:possible_values][l] = []
          end

          locale_alt = {}
          available_locales.each do |l|
            locale_alt[l] = available_locales.detect{|i| i != l}
          end

          self.values.each do |v|
            next unless v.translations

            translations_by_locale = {}
            v.translations.each do |t|
              next if translations_by_locale[t[:locale]]
              translations_by_locale[t[:locale]] = t
            end

            available_locales.each do |l|
              # TODO globalize and globalize fallback

              t = translations_by_locale[l]
              if t.blank? || t[:human_name].blank?
                t = translations_by_locale[locale_alt[l]] || t
              end
              human_name = t.present? && t[:human_name].present? ? t[:human_name] : nil
              result[:mapping][l][human_name] = v.id
              result[:mapping_invert][l][v.name] = human_name
              result[:possible_values][l] << {value: v.name, label: human_name || v.name}
            end
          end
          return result
        end
      end

      class Boolean < Base

        def self.indexed_type
          'boolean'
        end
      end

      class Date < Base
        enum format: {
          raw: 0, # default
          locale: 1, # default
          # 401
        }

        def self.indexed_type
          'date'
        end
      end

      class DateTime < Base
        enum format: {
          raw: 0, # default
          locale: 1,
          #iso8601: 501,
        }

        def self.indexed_type
          'date'
        end
      end

      class Enum < Base
        class Value < ::Dynamic::Schema::Base
          belongs_to :attr, class_name: 'Dynamic::Schema::Attribute::Base', inverse_of: :values
          def self.api_path
            @api_path||= [parent.api_path, ':attr_id', 'values'].join('/')
          end

          def self.api_id(resource)
            resource.id.to_s
          end
        end
        ::Dynamic::Schema::Attribute::Base.has_many :values, class_name: 'Dynamic::Schema::Attribute::Enum::Value', inverse_of: :attr

        def self.indexed_type
          'string'
        end
      end

      class Float < Base
        enum format: {
          locale: 1, # default
          x100_percentage: 301,
          thousands: 204,
          millions: 205,
          billions: 206,
          ppm: 207,
          unit: 202,
          currency: 203,
          # 208
          # 302
        }

        def self.indexed_type
          'number'
        end
      end

      class Integer < Base

        enum format: {
          locale: 1, # default
          percentage: 201,
          thousands: 204,
          millions: 205,
          billions: 206,
          ppm: 207,
          unit: 202,
          currency: 203,
          # 208
        }

        def self.indexed_type
          'number'
        end
      end

      class String < Base

        enum format: {
          raw: 0, # default
          # upcase: 101,
          # downcase: 102,
          # capitalize: 103,
          # upcase_first_letter: 104,
          phone: 105,
          # phone_international: 106,
          # french_city: 107,
          qrcode: 109,
        }

        enum editor: {
          text: 0, # default
          autocomplete: 1,
        }

        def self.indexed_type
          'string'
        end
      end

      class Text < Base

        enum format: {
          raw: 0,
          rich: 701,
        }

        def self.indexed_type
          'string'
        end
      end

      class TimeOfDay < Base

        enum format: {
          raw: 0, # default
          #locale: 1,
          # locale_hour_min: 601,
          # locale_hour_min_second: 602,
        }

        def self.indexed_type
          'string'
        end
      end

      class Uuid < Base
        def self.indexed_type
          'string'
        end
      end

      class TranslatableString < Base
        def self.indexed_type
          'string'
        end
      end
      class TranslatableText < Base
        def self.indexed_type
          'string'
        end
      end
    end

    module Association
      class Base <::Dynamic::Schema::Base
        translates :human_name
        globalize_accessors

        belongs_to :owner_klass, class_name: 'Dynamic::Klass', inverse_of: :associations
        belongs_to :target_klass, class_name: 'Dynamic::Klass'

        belongs_to :default_value_record, polymorphic: true
        has_many :default_value_records, polymorphic: true

        member_action :recompute_formula, http_method: :post

        class << self
          def api_path
            @api_path ||= [::Dynamic::Schema::Klass.api_path, ':klass_id', 'associations'].join('/')
          end

          def subclasses
            @subclasses ||= [
              'Dynamic::Schema::Association::BelongsTo',
              'Dynamic::Schema::Association::HasMany',
            ].map(&:constantize)
          end
        end

        def load_constants
          options = { class_name: target_klass&.const_absolute_name }
          if self.inverse_of_id
            inverse_of = owner_klass&.schema&.associations_by_id.try(:[], self.inverse_of_id)
            options[:inverse_of] = inverse_of.name if inverse_of
          end
          if self.dependent_destroy
            options[:dependent] = :destroy
          end
          owner_klass.const.send(self.class.name.demodulize.underscore, self.name, options)
          owner_klass.const.base_class.attribute_translations(self.name, self.translations)

          reflection = owner_klass.const.instance_variable_get(:@reflections)&.[](self.name)
          if reflection
            define_reflection_schema_association_through_name(reflection)
            define_reflection_default_elasticsearch_filters(reflection)
            define_reflection_default_elasticsearch_order(reflection)
          end
        end

        def define_reflection_schema_association_through_name(reflection)
          through_id = self.attributes['through_id']
          if self.through_id
            through_name = owner_klass&.schema&.associations_by_id.try(:[], self.through_id)&.name
          else
            through_name = nil
          end
          reflection.define_singleton_method(:schema_association_through_name) { through_name }
        end

        def define_reflection_default_elasticsearch_filters(reflection)
          default_elasticsearch_filters = self.attributes['default_elasticsearch_filters']
          reflection.define_singleton_method(:default_elasticsearch_filters) { default_elasticsearch_filters }
        end

        def define_reflection_default_elasticsearch_order(reflection)
          default_elasticsearch_order = self.attributes['default_elasticsearch_order']
          reflection.define_singleton_method(:default_elasticsearch_order) { default_elasticsearch_order }
        end

        def params_for_interpolate_path
          result = super
          result.merge!(klass_id: owner_klass_id) if owner_klass_id
          return result
        end
      end

      class HasMany < Base; end
      class BelongsTo < Base; end
    end

    module Attachment
      class Base <::Dynamic::Schema::Base
        translates :human_name
        globalize_accessors

        belongs_to :owner_klass, class_name: 'Dynamic::Klass', inverse_of: :attachments
        has_many :variants, class_name: 'Dynamic::Schema::Attachment::Variant', inverse_of: :attachment

        class << self
          def api_path
            @api_path ||= [::Dynamic::Schema::Klass.api_path, ':klass_id', 'attachments'].join('/')
          end

          def subclasses
            @subclasses ||= [
              'Dynamic::Schema::Attachment::HasOne',
              'Dynamic::Schema::Attachment::HasMany',
            ].map(&:constantize)
          end
        end

        def load_constants
          owner_klass.const.send("#{self.class.name.demodulize.underscore}_attached", self.name, {extensions: self.extensions, size_limit: self.size_limit})
          owner_klass.const.base_class.attribute_translations(self.name, self.translations)
        end

        def params_for_interpolate_path
          result = super
          result.merge!(klass_id: owner_klass_id) if owner_klass_id
          return result
        end
      end

      class HasOne < Base; end
      class HasMany < Base; end

      class Variant < ::Dynamic::Schema::Base
        def self.api_path
          @api_path ||= [::Dynamic::Schema::Klass.api_path, ':klass_id', 'attachments', ':attachment_id', 'variants'].join('/')
        end
        belongs_to :attachment, class_name: 'Dynamic::Schema::Attachment::Base'

        enum resize_type: {
          to_limit: 0 ,
          to_fit: 1,
          to_fill: 2,
          and_pad: 3,
        }

        enum format: {
          jpeg: 0 ,
          png: 1,
        }
      end
    end

    module Cascade
      class Base < ::Dynamic::Schema::Base
        belongs_to :klass, class_name: 'Dynamic::Schema::Klass'
      end
    end

    class Feature < Base
      belongs_to :schema, class_name: 'Dynamic::Schema', inverse_of: :features
      has_many :options, inverse_of: :owner, class_name: 'Dynamic::Schema::Option::Base', accepts_nested_attributes: true, allow_destroy: true
      has_many :concerns, inverse_of: :feature, class_name: 'Dynamic::Schema::Concern', accepts_nested_attributes: true, allow_destroy: true
      has_many :concern_templates, inverse_of: :feature, class_name: 'Dynamic::Schema::Concern', accepts_nested_attributes: true, allow_destroy: true
      translates :human_name
      globalize_accessors

      def const
        return @const if @const
        @const = self.name.safe_constantize
      end

      def load_constants
        begin
          self.name&.safe_constantize.try(:load_constants, self.schema)
          self.concerns.each(&:load_constants)
        rescue => e
          puts "fail to load constants of #{self.name} #{e.inspect}"
        end
      end

      def unload_constants
        begin
          self.name&.safe_constantize.try(:unload_constants, self.schema)
        rescue => e
          puts "fail to unload constants of #{self.name} #{e.inspect}"
        end
      end
    end

    class Concern < Base
      belongs_to :feature, inverse_of: :concerns, class_name: 'Dynamic::Schema::Feature', touch: true
      belongs_to :klass, class_name: 'Dynamic::Schema::Klass'
      belongs_to :schema, class_name: 'Dynamic::Schema'
      has_many :options, inverse_of: :owner, class_name: 'Dynamic::Schema::Option::Base', accepts_nested_attributes: true, allow_destroy: true

      translates :human_name
      globalize_accessors

      def initialize(*args)
        super
        if self.concern_template
          self.options = self.concern_template.options.map{|opt| {
            human_name_fr: opt.human_name_fr,
            human_name_en: opt.human_name_en,
            human_name: opt.human_name,
            name: opt.name,
            type: opt.type,
            value: opt.value
          }}
        end
      end

      def self.api_id(record)
        record.id
      end

      def const
        return @const if @const
        result = self.feature.const.try(:const_get, self.name) rescue nil
        result = self.feature.const&.parent.try(:const_get, self.name) if result.nil? || result.is_a?(Class)
        @const = result
      end

      def load_constants
        return unless self.klass
        begin
          const.try(:load_constants, self, self.feature.schema)
          # TODO include concerns to klass const
          self.klass.const.send(:include, const) if const
        rescue => e
          puts "fail to load constants of #{self.name} #{e.inspect}"
        end
      end

      def unload_constants
        begin
          const.try(:unload_constants, self.schema)
        rescue => e
          puts "fail to unload constants of #{self.name} #{e.inspect}"
        end
      end

      class << self
        def api_path
          @api_path ||= [::Dynamic::Schema::Feature.api_path, ':feature_id', 'concerns'].join('/')
        end

        def member_params_key
          "concern"
        end

      end
    end

    module Option
      class Base < ::Dynamic::Schema::Base
        has_one :owner, polymorphic: true, inverse_of: :options
        translates :human_name
        globalize_accessors

        def self.subclasses # TODO remove with opal 1.8.2
          [String, Boolean, Integer, Float, Hash]
        end

        def deserialized_value
          return value unless coder_type.present?
          coder_klass = coder_type.safe_constantize
          if coder_klass
            return coder_klass.new(owner.schema).load(value)
          else
            raise "missing coder #{coder_type}"
          end
        end
      end
      class String < Base; end
      class Boolean < Base; end
      class Integer < Base; end
      class Float < Base; end
      class Hash < Base; end

      module Coder
        class Base
          attr_accessor :schema
          def initialize(schema)
            @schema = schema
          end
          def load(v)
            v
          end
        end
        class Klass < Base
          def load(v)
            schema.klasses_by_id[v]
          end
        end
        class Klasses < Base
          def load(v)
            v.is_a?(::Array) ? v.map{|id| schema.klasses_by_id[id] } : []
          end
        end
        class Path < Base
          def load(v)
            v.is_a?(::Array) ? v.map{|id| schema.attr_or_assoc_or_attach_or_klass_by_id[id] } : []
          end
        end
        class AttrOrAssocOrAttach < Base
          def load(v)
            schema.attr_or_assoc_or_attach_by_id[v]
          end
        end
        class MappingOfAttrOrAssocOrAttach < Base
          def load(v)
            return {} unless v.is_a?(::Hash)
            result = {}
            v.each do |k_, v_|
              result[k_] = schema.attr_or_assoc_or_attach_by_id[v_]
            end
            return result
          end
        end
      end
    end

    module Migration
      class Base <::Dynamic::Schema::Base
        translates :human_name
        globalize_accessors

        belongs_to :schema, class_name: 'Dynamic::Schema', inverse_of: :migrations
      end
    end

    module Validation
      class Base < ::Dynamic::Schema::Base
        belongs_to :klass, inverse_of: :validations, class_name: 'Dynamic::Schema::Klass', foreign_key: :klass_id

        belongs_to :schema, inverse_of: :validations, class_name: 'Dynamic::Schema', touch: true, comes_from: :owner_klass

        has_one :attr, class_name: 'Dynamic::Schema::Attribute::Base'

        belongs_to :comparison_attr, inverse_of: :validations, class_name: 'Dynamic::Schema::Attribute::Base', foreign_key: :attr_id

        has_many :attrs, class_name: 'Dynamic::Schema::Attribute::Base'

        enum operator: [
          :greater_than,
          :greater_than_or_equal_to,
          :equal_to,
          :less_than,
          :less_than_or_equal_to,
          :other_than
        ]

        class << self
          def api_path
            @api_path ||= [::Dynamic::Schema::Klass.api_path, ':klass_id', 'validations'].join('/')
          end

          def member_params_key
            "validation"
          end

          def subclasses
            @subclasses ||= [
              'Dynamic::Schema::Validation::Presence',
              'Dynamic::Schema::Validation::AnyPresence',
              'Dynamic::Schema::Validation::Format::Base',
              'Dynamic::Schema::Validation::Format::Email',
              'Dynamic::Schema::Validation::Format::PhoneNumber',
              'Dynamic::Schema::Validation::Format::InternationalPhoneNumber',
              'Dynamic::Schema::Validation::Format::Siren',
              'Dynamic::Schema::Validation::Format::Siret',
              'Dynamic::Schema::Validation::Format::SirenSiret',
              'Dynamic::Schema::Validation::Comparison::Value',
              'Dynamic::Schema::Validation::Comparison::Attribute'
            ].map(&:constantize)
          end
        end
      end

      module Format
        class Base < ::Dynamic::Schema::Validation::Base; end
        class Email < Base; end
        class PhoneNumber < Base; end
        class InternationalPhoneNumber < Base; end
        class Siren < Base; end
        class Siret < Base; end
        class SirenSiret < Base; end
      end

      module Comparison
        class Base < ::Dynamic::Schema::Validation::Base; end
        class Value < Base; end
        class Attribute < Base; end
      end

      class Presence < ::Dynamic::Schema::Validation::Base; end
      class AnyPresence < ::Dynamic::Schema::Validation::Base; end
      class EitherPresence < ::Dynamic::Schema::Validation::Base; end
    end

    module Normalization
      class Base < ::Dynamic::Schema::Base
        belongs_to :klass, inverse_of: :normalizations, class_name: 'Dynamic::Schema::Klass', foreign_key: :klass_id, comes_from: :attr

        belongs_to :schema, inverse_of: :normalizations, class_name: 'Dynamic::Schema', touch: true, comes_from: :owner_klass

        belongs_to :attr, class_name: 'Dynamic::Schema::Attribute::Base'

        def human_name_from_type
          self.class.model_name.human
        end

        class << self
          def api_path
            @api_path ||= [::Dynamic::Schema::Klass.api_path, ':klass_id', 'attributes', ':attribute_id', 'normalizations'].join('/')
          end

          def member_params_key
            "normalization"
          end

          def subclasses
            @subclasses ||= [
              'Dynamic::Schema::Normalization::CapitalizeAllWords',
              'Dynamic::Schema::Normalization::CapitalizeFirstWord',
              'Dynamic::Schema::Normalization::Chomp',
              'Dynamic::Schema::Normalization::Lowercase',
              'Dynamic::Schema::Normalization::Mail',
              'Dynamic::Schema::Normalization::PhoneNumber',
              'Dynamic::Schema::Normalization::Siret',
              'Dynamic::Schema::Normalization::Strip',
              'Dynamic::Schema::Normalization::Upcase',
            ].map(&:constantize)
          end

          def name_attribute
            :human_name_from_type
          end
        end
      end

      class CapitalizeAllWords < ::Dynamic::Schema::Normalization::Base; end
      class CapitalizeFirstWord < ::Dynamic::Schema::Normalization::Base; end
      class Chomp < ::Dynamic::Schema::Normalization::Base; end
      class Lowercase < ::Dynamic::Schema::Normalization::Base; end
      class Mail < ::Dynamic::Schema::Normalization::Base; end
      class PhoneNumber < ::Dynamic::Schema::Normalization::Base; end
      class Siret < ::Dynamic::Schema::Normalization::Base; end
      class Strip < ::Dynamic::Schema::Normalization::Base; end
      class Upcase < ::Dynamic::Schema::Normalization::Base; end
    end

    class Sequence < Base
      belongs_to :schema, class_name: 'Dynamic::Schema', inverse_of: :sequences
      belongs_to :attr, class_name: 'Dynamic::Schema::Attribute::String', inverse_of: :attr

      enum condition_type: {none: 0, attr: 1, type: 2}

      class << self
        def api_path
          @api_path ||= [::Dynamic::Schema::Attribute::Base.api_path, ':attr_id', 'sequences'].join('/')
        end

        def exceptions_for_update
          [:format_example]
        end
      end
    end
  end
end
