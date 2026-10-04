# backtick_javascript: true

module Dynamic
  class Form < Base
    class << self
      def api_path
        @api_path ||= [::Dynamic::Schema.api_path, ':schema_id', 'forms'].join('/')
      end
    end

    translates :human_name
    globalize_accessors

    belongs_to :schema, class_name: 'Dynamic::Schema', inverse_of: :forms
    has_many :elements, class_name: 'Dynamic::Form::Element::Base', inverse_of: :form
    belongs_to :theme, class_name: 'Dynamic::Theme'
    has_many :cascades, class_name: 'Dynamic::Cascade', accept_nested_attributes: true

    member_action :submit, {
      http_method: :post,
      add_attributes_as_params: [
        :source_record_type,
        :source_record_id,
        :target_record_type,
        :target_record_id,
      ]
    }

    member_action :save_as_draft, {
      http_method: :post,
      add_attributes_as_params: [
        :source_record_type,
        :source_record_id,
        :target_record_type,
        :target_record_id,
      ]
    }

    member_action :submit_all, {
      http_method: :post,
    }

    member_action :duplicate, {
      http_method: :post,
    }

    enum mode: {
      input: 0,
      edit_in_place: 1,
      read_only: 2,
    }, _prefix: true

    AVAILABLE_MODES_FOR_ACTION = {
      show: [:read_only, :read_only_as_table],
      new: [:input],
      edit: [:input, :edit_in_place],
      submit_all: [:input],
    }

    ACTIONS = ['new', 'edit', 'show', 'submit_all']

    def self.actions
      ACTIONS
    end

    scope :with_action

    def self.available_modes(actions)
      actions&.map{|a| AVAILABLE_MODES_FOR_ACTION[a]}&.inject(&:&) || self.modes.keys
    end

    def travel(&block)
      return root_elements.map{|e| travel_(e, &block) }
    end

    def travel_(e, &block)
      children_result = e.children.map do |c|
        travel_(c, &block)
      end
      return yield(e, children_result)
    end

    def root_elements
      elements_by_parent_id[nil] || []
    end

    def element_by_id
      return @element_by_id if @element_by_id && loaded?
      @element_by_id ||= {}
      elements.each do |e|
        @element_by_id[e.id] = e
      end
      @element_by_id
    end

    def elements_by_parent_id
      return @elements_by_parent_id if @elements_by_parent_id && loaded?
      @elements_by_parent_id ||= {}
      elements.each do |e|
        @elements_by_parent_id[e.parent_id] ||= []
        @elements_by_parent_id[e.parent_id] << e
      end
      @elements_by_parent_id.each do |k, v|
        next unless v
        @elements_by_parent_id[k] = v.sort_by{|e| e.position || 0}
      end
      return @elements_by_parent_id
    end

    def record_for_element(element, submission)
      submission.record_for_input_prefix ||= {}

      result = submission.record_for_input_prefix[element.normalized_input_prefix]

      return result if result

      if serialized_record_for_input_prefix
        record_attributes = serialized_record_for_input_prefix[element.normalized_input_prefix].deep_dup || {}
      else
        record_attributes = {}
      end

      path = element.normalized_input_prefix.split(/\@|\./)

      record_klass = element.klass_name.safe_constantize || HyperResource::Base

      record_klass.reflect_on_all_associations.each do |a|
        values = extract_attributes_from_serialized_record_for_input_prefix[path].try(:[], a.name)
        next unless values
        values = values.first if !a.collection? && values.is_a?(Array) # an embedded belongs_to (schema default) is serialized as a hash
        record_attributes[a.name] = values.deep_dup
      end

      result = record_klass.polymorphic_new_and_keep_initial_json(record_attributes)

      submission.record_for_input_prefix[element.normalized_input_prefix] = result

      return result
    end

    def extract_attributes_from_serialized_record_for_input_prefix
      return @extracted_attributes if @extracted_attributes
      tmp = {}
      serialized_record_for_input_prefix&.each do |input_prefix, value|
        h = tmp
        input_prefix.split('.').each do |part|
          k, i = part.split('@')
          h[k] ||= {}
          h[k][i] ||= {}
          h = h[k][i]
        end
        h.merge!(value)
      end

      result = {}
      serialized_record_for_input_prefix&.keys&.each do |input_prefix|
        path = []
        input_prefix.split('.').each do |part|
          k, i = part.split('@')
          path = path + (i ? [k, i] : [k])
          r = remove_nums(tmp.dig(*path))
          result[path] = r if r
        end
      end

      @extracted_attributes = result
      return result
    end

    def remove_nums(o)
      case o
      when Array
        o.map{|e| remove_nums(e) }
      when Hash
        if o.keys.first =~ /^\d+$/
            o.sort.map{|a| remove_nums(a[1])}
        else
          o.transform_values{|v| remove_nums(v)}
        end
      else
        o
      end
    end

    def json=(j)
      init_instance_variables
      super
    end

    def init_instance_variables
      @extracted_attributes = nil
      @autocomplete_includes = nil
    end

    class << self
      def load(params, &block)
        elements_include = {
          input_prefix: 1,
          normalized_input_prefix: 1,
          parent_id: 1,
          possible_values: {
            include: {
              value_record: 1,
            }
          },
          default_value_record: 1,
          default_value_records: 1,
        }

        if params[:source_record]

          params_ = params.dup
          params_.delete(:id)

          # assume load form with source_record in the frontend
          source_record = params_.delete(:source_record)
          target_record = params_.delete(:target_record)

          includes_ = {
            cascades: 1,
            elements: {
              include: elements_include,
            },
          }

          if params[:source_record_id] || params[:target_record_id]
            includes_[:serialized_record_for_input_prefix] = 1
          end

          result = includes(includes_).where(params_).find(params[:id], &block)

          result.attributes['source_record'] = source_record
          result.attributes['target_record'] = target_record

        else
          # load form in backend

          result = includes(
            loaded_elements: {
              as: :elements,
              include: elements_include,
            },
            cascades: 1,
            serialized_record_for_input_prefix: 1,
          ).where(params).find(params[:id]) do |form|
            form.attributes['source_record_type'] = params[:source_record_type]
            form.attributes['source_record_id'] = params[:source_record_id]
            form.attributes['target_record_type'] = params[:target_record_type]
            form.attributes['target_record_id'] = params[:target_record_id]
            yield(form) if block_given?
          end

        end

        return result
      end

      def clear_cache_with_serialized_records
        self.cache[:find]&.delete_if{|k, v| k.dig(:include, :serialized_record_for_input_prefix)}
      end

    end

    def association(r = nil)
      return super if r # beurk

      return unless association_name.present?

      k = association_klass_name if association_klass_name.present?
      k = source_klass_name if k.nil? && source_klass_name.present? # why source_klass_name != association_klass_name ?

      return unless k

      return "#{k}.#{association_name}"
    end

    def association=(v)
      case v
      when String
        self.association_klass_name, self.association_name = v.split('.')
        self.association_klass_name = self.association_klass_name&.classify
        self.source_klass_name = self.association_klass_name unless self.source_klass_name.present? # why still needed ?
      when HyperResource::Reflection::Base
        self.association_klass_name = v.active_record.name
        self.association_name = v.name.to_s
        self.source_klass_name = self.association_klass_name unless self.source_klass_name.present? # why still needed ?
      end
    end

    def association_reflection
      self.association_klass_name&.safe_constantize&.reflect_on_association(self.association_name)
    end

    def autocomplete_includes(prefix_path)
      return @autocomplete_includes[prefix_path] if @autocomplete_includes&.has_key?(prefix_path)

      @autocomplete_includes ||= {}
      @autocomplete_includes[prefix_path] = {}
      method_names = prefix_path.select{|p, i| !p.is_a?(Integer) }
      method_names.shift

      elements.each do |e|
        if method_names == e.method_names
          @autocomplete_includes[prefix_path][:only] ||= []
          @autocomplete_includes[prefix_path][:only] << 'id' unless @autocomplete_includes[prefix_path][:only].include?('id')
          # include type ?
          case e
          when Dynamic::Form::Element::Attribute::Translatable
            I18n.available_locales.each do |l|
              attr = "#{e.attribute_name}_#{l}"
              next if @autocomplete_includes[prefix_path][:only].include?(attr)
              @autocomplete_includes[prefix_path][:only] << attr
            end
          when Dynamic::Form::Element::Attribute::Base
            next if @autocomplete_includes[prefix_path][:only].include?(e.attribute_name)
            @autocomplete_includes[prefix_path][:only] << e.attribute_name
          when Dynamic::Form::Element::Association::Base
            @autocomplete_includes[prefix_path][:include] ||= {}
            h = @autocomplete_includes[prefix_path][:include][e.attribute_name] ||= {}
            includes = autocomplete_includes(prefix_path + [e.attribute_name])
            h.merge!(includes) if includes.is_a?(Hash) # deep_merge?
            h[:only] ||= []
            h[:only] << 'id' unless h[:only].include?('id')
            h[:only] << 'type' unless h[:only].include?('type')
            name_attr = e.klass&.reflect_on_association(e.attribute_name)&.klass.try(:name_attribute) # TODO polymorphic
            h[:only] << name_attr if name_attr && !h[:only].include?(name_attr)
          when Dynamic::Form::Element::Attachment::Base
            @autocomplete_includes[prefix_path][:include] ||= {}
            @autocomplete_includes[prefix_path][:include][e.attribute_name] = ::HyperResource::Base.active_storage_includes
          end
        end
      end

      return @autocomplete_includes[prefix_path]
    end

    class Base < ::Dynamic::Base
    end

    module Element
      class Base < ::Dynamic::Form::Base
        belongs_to :form, class_name: 'Dynamic::Form', inverse_of: :elements
        belongs_to :default_value_record, polymorphic: true
        has_many :default_value_records, polymorphic: true
        has_many :possible_values, class_name: 'Dynamic::Form::Element::PossibleValue', inverse_of: :element

        belongs_to :parent, class_name: 'Dynamic::Form::Element::Base', foreign_key: 'parent_id', optional: true

        attribute :show_value, :boolean, default: true
        attribute :show_label, :boolean, default: true

        def input_prefix_path
          @input_prefix_path ||= normalized_input_prefix&.split(/\.|@/)&.map{|e| e =~ /^\d+$/ ? e.to_i : e}
        end

        def children
          form.elements_by_parent_id[self.id] || []
        end

        def enum_values
          if possible_values.try(:any?)
            return possible_values.sort_by(&:position).map{|pv| {label: pv.text, value: pv.value} }
          else
            return klass&.attributes&.dig(attribute_name, :possible_values, I18n.locale) || []
          end
        end

        def association_values
          return possible_values.select{|pv| pv.value_record}.sort_by(&:position).map{|pv| {label: pv.text, value: pv.value_record} }
        end

        def values
          if klass&.reflect_on_association(attribute_name)
            association_values
          else
            enum_values
          end
        end

        def klass
          klass_name&.safe_constantize
        end

        def root_klass
          root_klass_name&.safe_constantize
        end

        # editor values:
        # usual html editors:
        #   text: 1,
        #   textarea: 2
        #   checkbox: 3,
        #   radio: 4,
        #   'select': 5,
        #   number: 6
        #   hidden: 7
        # javascript components:
        #   select2: 102,

        enum editor: {
          hidden: 7,
        }

        enum value_position: {
          right: 0,
          top: 1,
        }

        enum requirement: {
          optional: 0,
          important: 1,
          mandatory: 2,
        }

        enum autocomplete_mode: {
          none: 0,
          restricted: 1,
          full: 2,
        }, _prefix: true

        enum record_type_for_default_value_formula: {
          root_record: 0,
          target_record: 1,
        }

        translates [:label, :text, :watermark, :help, :translated_default_value]
        globalize_accessors
      end

      class PossibleValue < ::Dynamic::Form::Base;
        belongs_to :element, class_name: 'Dynamic::Form::Element::Base', inverse_of: :possible_values
        belongs_to :value_record, polymorphic: true
        attribute :position, {type: 'Integer'}
        def position=(v) # it should be defined by attribute() ?
          self.attributes['position'] = v
        end

        translates [:text]
        globalize_accessors
      end

      module Attribute
        class Base < ::Dynamic::Form::Element::Base

          attribute :disabled, type: 'Boolean', default: false
          attribute :read_only, type: 'Boolean', default: false

          class << self
            def subclasses
              @subclasses ||= [
                'Dynamic::Form::Element::Attribute::String',
                'Dynamic::Form::Element::Attribute::Text',
                'Dynamic::Form::Element::Attribute::Integer',
                'Dynamic::Form::Element::Attribute::Float',
                'Dynamic::Form::Element::Attribute::Boolean',
                'Dynamic::Form::Element::Attribute::Date',
                'Dynamic::Form::Element::Attribute::DateTime',
                'Dynamic::Form::Element::Attribute::TimeOfDay',
                'Dynamic::Form::Element::Attribute::TranslatableString',
                'Dynamic::Form::Element::Attribute::TranslatableText',
                'Dynamic::Form::Element::Attribute::Enum',
              ].map(&:constantize)
            end
          end

        end


        class Boolean < Base
          enum editor: {
            radio: 4,
            radio_inline: 4,
            hidden: 7,
            switch: 11,
          }
        end

        class Date < Base
          enum editor: {
            hidden: 7,
          }
        end

        class DateTime < Base
          enum editor: {
            hidden: 7,
          }
        end

        class Float < Base
          enum editor: {
            number: 6,
            hidden: 7,
          }
        end

        class Integer < Base
          enum editor: {
            number: 6,
            hidden: 7,
          }
        end

        class String < Base
          enum editor: {
            text: 1,
            hidden: 7,
            tel: 8,
            qrcode: 12,
            autocomplete: 5,
          }
        end

        class Text < Base
          enum editor: {
            hidden: 7,
            textarea: 2,
            tinymce: 13,
          }
        end

        class TimeOfDay < Base
          enum editor: {
            hidden: 7,
          }
        end

        module Translatable
          def default_value
            result = {}
            I18n.available_locales.each do |l|
              result[l] = send(:"translated_default_value_#{l}")
            end
            return result
          end
        end

        class TranslatableString < Base
          include Translatable

          enum editor: {
            text: 1,
            hidden: 7,
          }
        end

        class TranslatableText < Base
          include Translatable

          enum editor: {
            textarea: 2,
            hidden: 7,
          }
        end

        class Enum < Base
          enum editor: {
            radio: 4,
            radio_inline: 4,
            hidden: 7,
            step: 9,
            step_inline: 9,
          }
        end
      end

      module Association
        class Base < ::Dynamic::Form::Element::Base
          class << self
            def subclasses
              @subclasses ||= [
                'Dynamic::Form::Element::Association::BelongsTo',
                'Dynamic::Form::Element::Association::HasMany',
              ].map(&:constantize)
            end
          end
        end

        class HasMany < Base
          enum editor: {
            checkbox: 3,
            checkbox_inline: 3,
            'select': 5,
            select2: 102,
            hidden: 7,
          }

          enum mode: {
            input: 0,
            edit_in_place: 1,
            read_only: 2,
            nested_form: 10,
          }

          def default_value
            default_value_records
          end
        end

        class BelongsTo < Base
          enum editor: {
            radio: 4,
            'select': 5,
            radio_inline: 4,
            hidden: 7,
          }

          def default_value
            default_value_record
          end
        end
      end

      module Attachment
        class Base < ::Dynamic::Form::Element::Base
          class << self
            def subclasses
              @subclasses ||= [
                'Dynamic::Form::Element::Attachment::HasOne',
                'Dynamic::Form::Element::Attachment::HasMany',
              ].map(&:constantize)
            end
          end
        end

        class HasOne < Base
        end

        class HasMany < Base
        end
      end

      module Layout
        class Base < ::Dynamic::Form::Element::Base
          class << self
            def subclasses
              @subclasses ||= [
                'Dynamic::Form::Element::Layout::Container',
                'Dynamic::Form::Element::Layout::Column',
                'Dynamic::Form::Element::Layout::Condition',
                'Dynamic::Form::Element::Layout::Row',
                'Dynamic::Form::Element::Layout::Section',
                'Dynamic::Form::Element::Layout::Page',
                'Dynamic::Form::Element::Layout::AdditionalFieldsContainer',
              ].map(&:constantize)
            end
          end
        end

        class Container < Base; end
        class Column < Base; end
        class Condition < Base
          class Evaluator
            KEY_OPERATOR_FOR_DATE = 'ago'
            BOOLEAN_VALUES = {'0' => false, '1' => true, false => false, true => true}

            def initialize(condition_formula)
              @condition_formula = condition_formula
            end

            def run_eval(get_attributes_value)
              @get_attributes_value = get_attributes_value
              conditions_str = to_string_representation(@condition_formula)
              return evaluate_conditions(conditions_str)
            end

            def to_string_representation(list_conditions, res=[], parent_key='')
              if list_conditions.is_a?(Hash)
                list_conditions.each do |key, value|
                  if value.is_a?(Array) && key != KEY_OPERATOR_FOR_DATE
                    length = value.length - 1
                    value.each_with_index do |item, index|
                      res << "("
                      to_string_representation(item, res)
                      res << ")"
                      res << convert_boolean_operator(key) unless index == length
                    end
                  elsif value.is_a?(Hash) && !value.has_key?('variable')
                    to_string_representation(value, res, key)
                  else
                    res << compute_value_with_operator(parent_key, key, value)
                  end
                end
              end
              return res.join
            end

            def compute_value_with_operator(path, operator, value)
              expected_value = value
              expected_value = @get_attributes_value.call(value['variable']) if value.is_a?(Hash) && !value.has_key?(KEY_OPERATOR_FOR_DATE)
              value_on_form = @get_attributes_value.call(path)
              if apply_on_elements?(operator, value_on_form)
                return "(#{operator.include?('not_') ? 'true' : 'false'})" if value_on_form.empty?
                logic_op = operator.include?('not_') ? ' && ' : ' || '
                return "(#{value_on_form.map { |v_o_f| send(operator, v_o_f, expected_value) }.join(logic_op)})"
              else
                return send(operator, value_on_form, expected_value)
              end
            end

            def evaluate_conditions(conditions_str)
              return true if conditions_str =~ /\A[()]*\z/ # conditions_str is an empty '(())'
              raise "INVALID DATA #{conditions_str}" unless conditions_string_valid?(conditions_str)# ensure a valid string to eval
              if RUBY_ENGINE == 'opal'
                return `eval(#{conditions_str})`
              else
                return eval(conditions_str)
              end
            end

            private

            def convert_boolean_operator(key)
              {'and' => '&&', 'or' => '||'}[key]
            end

            def apply_on_elements?(operator, value_on_form) # behavior about array is inconsistent :(
              value_on_form.is_a?(Array) && (!value_on_form.empty? || !operator.end_with?('empty'))
            end

            def conditions_string_valid?(conditions_str)
              return false if conditions_str.include?('()')
              pattern = /\A(?:\(|\)| |\|\||\&\&|true|false)*\z/
              return !!(conditions_str =~ pattern)
            end

            def contains(value_on_forms, expected_value)
              return false if expected_value.blank? || value_on_forms.blank?
              value_on_forms = value_on_forms.to_s if value_on_forms.is_a?(Integer)
              expected_value = expected_value.to_s if expected_value.is_a?(Integer)
              value_on_forms.include?(expected_value)
            end

            def not_contains(value_on_forms, expected_value)
              return true if expected_value.blank?
              return false if value_on_forms.blank?
              value_on_forms = value_on_forms.to_s if value_on_forms.is_a?(Integer)
              expected_value = expected_value.to_s if expected_value.is_a?(Integer)
              !value_on_forms.include?(expected_value)
            end

            def equal(value_on_forms, expected_value)
              return boolean_equal(value_on_forms,expected_value) if expected_value.is_a?(Boolean)
              return false if value_on_forms.blank?
              value_on_forms == expected_value
            end

            def boolean_equal(value_on_forms, expected_value)
              return BOOLEAN_VALUES[value_on_forms] == expected_value
            end

            def not_equal(value_on_forms, expected_value)
              return boolean_not_equal(value_on_forms,expected_value) if expected_value.is_a?(Boolean)
              return true if value_on_forms.blank?
              value_on_forms != expected_value
            end

            def boolean_not_equal(value_on_forms, expected_value)
              return BOOLEAN_VALUES[value_on_forms] != expected_value
            end

            def greater_equal(value_on_forms, expected_value)
              return false if value_on_forms.blank?
              value_on_forms.to_f >= expected_value.to_f
            end

            def lesser_equal(value_on_forms, expected_value)
              return false if value_on_forms.blank?
              value_on_forms.to_f <= expected_value.to_f
            end

            def empty(value_on_forms, expected_value)
              return false if value_on_forms == false
              value_on_forms.blank?
            end

            def not_empty(value_on_forms, expected_value)
              return true if value_on_forms == false
              !value_on_forms.blank?
            end

            def starts_with(value_on_forms, expected_value)
              return true if expected_value.blank?
              return false if value_on_forms.blank?
              value_on_forms.start_with?(expected_value)
            end

            def ends_with(value_on_forms, expected_value)
              return true if expected_value.blank?
              return false if value_on_forms.blank?
              value_on_forms.end_with?(expected_value)
            end

            def length_equal_to(value_on_forms, expected_value)
              return true if expected_value.blank?
              return false if value_on_forms.blank?
              value_on_forms&.length == expected_value.to_i
            end

            def before(value_on_forms, expected_value)
              return false if [value_on_forms,expected_value].any?(&:blank?)

              value_on_forms = Time.parse(value_on_forms)
              expected_value = Time.parse(expected_value)
              return value_on_forms < expected_value
            end

            def after(value_on_forms, expected_value)
              return false if [value_on_forms,expected_value].any?(&:blank?)

              value_on_forms = Time.parse(value_on_forms)
              expected_value = Time.parse(expected_value)
              return value_on_forms > expected_value
            end

            def today(value_on_forms, expected_value)
              return false if value_on_forms.blank?
              value_on_forms = Time.parse(value_on_forms).strftime("%Y-%m-%d")
              expected_value = Time.now.strftime("%Y-%m-%d")

              return value_on_forms == expected_value
            end

            def ago(value_on_forms, expected_value)
              return false if [value_on_forms, expected_value].any?(&:blank?)
              value_on_forms = Time.parse(value_on_forms)
              n, unit = expected_value # [5, "years"] # [6, days] # [6, seonconds] ...
              expected_value = n.send(unit).ago

              return value_on_forms <= expected_value
            end

            def since(value_on_forms, expected_value)
              return false if [value_on_forms, expected_value].any?(&:blank?)
              value_on_forms = Time.parse(value_on_forms)
              n, unit = expected_value # [5, "years"] # [6, days] # [6, seonconds] ...
              expected_value = n.send(unit).ago

              return value_on_forms >= expected_value
            end

            def until(value_on_forms, expected_value)
              return false if [value_on_forms, expected_value].any?(&:blank?)
              value_on_forms = Time.parse(value_on_forms)
              n, unit = expected_value # [5, "years"] # [6, days] # [6, seonconds] ...
                expected_value = n.send(unit).from_now

              return value_on_forms <= expected_value
            end

            def this_week(value_on_forms, expected_value)
              return false if value_on_forms.blank?

              value_on_forms = Time.parse(value_on_forms)
              time = Time.now
              start_of_week = time - time.wday * 86400
              end_of_week = start_of_week + 7 * 86400
              return value_on_forms >= start_of_week && value_on_forms <= end_of_week
            end

            def this_year(value_on_forms, expected_value)
              return false if value_on_forms.blank?

              value_on_forms = Time.parse(value_on_forms)
              return Time.now.year == value_on_forms.year
            end

            def this_month(value_on_forms, expected_value)
              return false if value_on_forms.blank?

              value_on_forms = Time.parse(value_on_forms)
              time = Time.now
              start_of_month = Time.new(time.year, time.month, 1)
              end_of_month = Time.new(time.year, time.month + 1, 1) - 1

              return value_on_forms >= start_of_month && value_on_forms <= end_of_month
            end

            def date_equal(value_on_forms, expected_value)
              return false if [value_on_forms, expected_value].any?(&:blank?)

              value_on_forms = Time.parse(value_on_forms).strftime("%Y-%m-%d")
              expected_value = Time.parse(expected_value).strftime("%Y-%m-%d")
              return value_on_forms == expected_value
            end

            def date_not_equal(value_on_forms, expected_value)
              return false if [value_on_forms, expected_value].any?(&:blank?)

              value_on_forms = Time.parse(value_on_forms).strftime("%Y-%m-%d")
              expected_value = Time.parse(expected_value).strftime("%Y-%m-%d")
              return value_on_forms != expected_value
            end

            def contains_id(value_on_forms, expected_value)
              return true if expected_value.blank?
              return false if value_on_forms.blank?
              value_on_forms[:id] == expected_value
            end

            def not_contains_id(value_on_forms, expected_value)
              return true if [value_on_forms, expected_value].any?(&:blank?)
              value_on_forms[:id] != expected_value
            end

            def contains_name(value_on_forms, expected_value)
              #TO DO
            end

            def not_contains_name(value_on_forms, expected_value)
              #TO DO
            end

            def equal_id(value_on_forms, expected_value)
              contains_id(value_on_forms, expected_value)
            end

            def not_equal_id(value_on_forms, expected_value)
              not_contains_id(value_on_forms, expected_value)
            end
          end
        end
        class Row < Base; end
        class Section < Base; end
        class Page < Container; end
        class AdditionalFieldsContainer < Base; end
      end

      module Basic
        class Base < ::Dynamic::Form::Element::Base
          class << self
            def subclasses
              @subclasses ||= [
                'Dynamic::Form::Element::Basic::Text',
              ].map(&:constantize)
            end
          end
        end
        class Text < Base
          has_many_attached :attachments
        end
      end

      module Control
        class Base < ::Dynamic::Form::Element::Base
          class << self
            def subclasses
              @subclasses ||= [
                'Dynamic::Form::Element::Control::AddButton',
                'Dynamic::Form::Element::Control::Navigation',
                'Dynamic::Form::Element::Control::Print',
              ].map(&:constantize)
            end
          end

        end
        class AddButton < Base
          def attribute_name
            method_names.last
          end

          def normalized_input_prefix # redefined in order to return parent prefix
            return attributes['normalized_input_prefix']&.gsub(/\.([^\.]+)$/, '')
          end

          def klass_name # redefined in order to return parent class name
            return @klass_name if @klass_name
            return unless attributes['normalized_input_prefix']

            path = attributes['normalized_input_prefix'].gsub(/@\d+/, '').split('.')
            path.shift # remove root_klass_name
            path.pop # remove last

            return root_klass_name if path.empty?

            k = root_klass_name.safe_constantize
            while k && (p = path.shift)
              k = k.reflect_on_association(p)&.klass
            end
            @klass_name = k&.name
          end
        end

        class Navigation < Base
          translates [
            :previous_button_text,
            :next_button_text,
            :cancel_button_text,
            :submit_button_text,
          ]
          globalize_accessors
        end
        class Print < Base; end
      end
    end

    class Submission < Base
      def self.api_path
        @api_path ||= [::Dynamic::Schema.api_path, ':schema_id', 'form_submissions'].join('/')
      end
    end
  end
end
