module Dynamic
  module Transaction
    module ApplicableAmount

      class Rule < ::Dynamic::Base
        define_api_path

        has_many :conditions, class_name: 'Dynamic::Transaction::ApplicableAmount::Condition', foreign_key: :rule_id, inverse_of: :rule, accept_nested_attributes: true

        enum applicability: {
          on_base: 0,
          previous_operation: 1,
        }

        class << self
          def feature
            'Dynamic::Transaction::Feature'
          end

          def name_attribute
            'human_name'
          end
        end

      end

      class Condition < ::Dynamic::Base

        AUTHORIZED_METHODS_BY_TYPE = {
          'string' => ['==', '!=', 'start_with?', 'end_with?', 'include?', 'exclude?'],
          'integer' => ['>', '<', '<=', '>=', '==', '!='],
          'float' => ['>', '<', '<=', '>=', '==', '!='],
          'enum' => ['==', '!='],
          'date' => ['>', '<', '>=', '<=', '==', '!='],
          'boolean' => ['=='],
          'uuid' => ['==', '!='],
        }.freeze

        define_api_path

        belongs_to :rule, class_name: 'Dynamic::Transaction::ApplicableAmount::Rule', inverse_of: :conditions

        enum expression_value_type: {
          string: 0,
          integer: 1,
          float: 2,
          enumtype: 3,
          date: 4,
          boolean: 5,
          safeenumtype: 6,
          uuid: 7
        }

      end

    end

  end

end
