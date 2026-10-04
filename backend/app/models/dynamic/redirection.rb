# frozen_string_literal: true

require 'dynamic_record'

module Dynamic
  class Redirection < ActiveRecord::Base
    self.table_name = 'dynamic_redirections'

    belongs_to :schema, class_name: 'Dynamic::Schema', inverse_of: :redirections
    belongs_to :klass, class_name: 'Dynamic::Schema::Klass', optional: true

    validates :name, presence: true, uniqueness: { scope: :schema_id }

    before_validation :transform_name, if: :transform_name?

    def transform_name
      self.name = I18n.transliterate(self.name.strip).gsub(/\A\d+/, '').underscore.gsub(/[^[:alpha:]0-9\_]/, '_')
    end

    def transform_name?
      !(self.name.blank? || !self.name_changed?)
    end

    def evaluate(params = {})
      prepare(params)

      if condition
        Dynamic::Schema.load(schema.name)

        if condition.evaluate
          {
            type: target_type,
            params: target_helper.params || {}
          }
        else
          {
            type: fallback_type,
            params: fallback_helper&.params || {}
          }
        end
      else
        {
          type: nil,
          params: {},
        }
      end
    end

    attr_reader :condition, :target_helper, :fallback_helper

    def prepare(evaluation_params)
      evaluation_params = evaluation_params.last if evaluation_params.is_a?(::Array) # TODO fix as_deep_json when args are hash with num keys

      @target_helper = nil
      @fallback_helper = nil
      @condition = nil

      if target_type.present?
        @target_helper = self.class.const_get(target_type)&.new(schema, klass, target_formula, target_params, evaluation_params)
      end

      if fallback_type.present?
        @fallback_helper = self.class.const_get(fallback_type)&.new(schema, klass, fallback_formula, fallback_params, evaluation_params)
      end

      if @target_helper
        condition_klass = condition_type.present? ? self.class.const_get(condition_type) : Condition
        @condition = condition_klass&.new(@target_helper)
      end
    end

    class Condition

      attr_reader :helper

      def initialize(helper)
        @helper = helper
      end

      def evaluate
        return true
      end

    end

    class Permission < Condition

      def evaluate
        return !!helper&.records&.all?{|r| r.try(:can_be_read_by?, User.current || UneekPermission::PredefinedReceiver::Public.instance ) }
      end

    end

    class Helper
      attr_reader :schema, :schema_klass, :formula, :helper_params, :evaluation_params

      def initialize(schema, schema_klass, formula, helper_params, evaluation_params)
        @schema = schema
        @schema_klass = schema_klass
        @formula = ::Dynamic::Formula.new(formula) if formula.present?
        @helper_params = helper_params
        @evaluation_params = evaluation_params
      end

      def records
        [record]
      end

      def record
        return @record if @record_computed
        @record_computed = true
        if formula
          if root_record
            @record = formula.eval(record: root_record) rescue nil
            @record = nil unless @record.is_a?(::ActiveRecord::Base)
          end
        else
          @record = root_record
        end
        return @record
      end

      def root_record
        return unless root_klass && root_id
        @root_record ||= root_klass&.find_by(id: root_id)
      end

      def root_klass
        schema_klass&.const
      end

      def root_id
        evaluation_params['for']
      end

      def record_schema_klass
        return unless record
        return schema_klass if record.class == root_klass
        return @record_schema_klass ||= schema.klasses.detect{|k| k.const_absolute_name == record.class.name}
      end

      def params
        raise 'not implemented'
      end
    end

    class Form < Helper

      def records
        if evaluation_params['for']
          [record, form]
        else
          [form]
        end
      end

      def form
        Dynamic::Form.find_by(id: helper_params['form_id'])
      end

      def params
        result = helper_params.deep_dup
        result.deep_symbolize_keys!
        result.merge!(schema_id: schema.name)
        result.merge!(klass_name: record.class.name, id: record.id) if record
        return result
      end

    end

    class Vcard < Helper

      def params
        {
          schema_name: schema.name.underscore,
          route_key: record_schema_klass&.route_key,
          id: record&.id,
        }
      end

    end

  end
end
