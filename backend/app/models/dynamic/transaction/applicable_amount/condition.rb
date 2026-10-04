module Dynamic
  module Transaction
    module ApplicableAmount

      class Condition < ActiveRecord::Base
        self.table_name = 'applicable_amount_conditions'

        include Dynamic::Mount

        AUTHORIZED_METHODS_BY_TYPE = {
          'string' => ['==', '!=', 'start_with?', 'end_with?', 'include?', 'exclude?'],
          'integer' => ['>', '<', '<=', '>=', '==', '!='],
          'float' => ['>', '<', '<=', '>=', '==', '!='],
          'enumtype' => ['==', '!='],
          'date' => ['>', '<', '>=', '<=', '==', '!='],
          'boolean' => ['=='],
          'safeenumtype' => ['==', '!='],
          'uuid' => ['==', '!='],
        }.freeze

        define_table do |t|
          t.text       :instance_field
          t.string     :expression_method
          t.string     :expression_value
          t.integer    :expression_value_type
          t.belongs_to :rule, type: :uuid
        end

        after_mount do
          enum :expression_value_type, {
            string: 0,
            integer: 1,
            float: 2,
            enumtype: 3,
            date: 4,
            boolean: 5,
            safeenumtype: 6,
            uuid: 7
          }

          serialize :instance_field, type: ::Array, coder: ::YAML

          validates :expression_method, :instance_field, :expression_value, :expression_value_type, presence: true

          validates :expression_method, inclusion: {
            in: ->(condition) {
              Dynamic::Transaction::ApplicableAmount::Condition::AUTHORIZED_METHODS_BY_TYPE[condition.expression_value_type]
            }
          }

          belongs_to :rule, class_name: 'Rule', inverse_of: :conditions, touch: true
        end

        def applicable_to?(transaction_line)
          result = false

          inst_f = evaluate(transaction_line, instance_field)
          return result if inst_f.nil?

          result = if inst_f.is_a?(::Array) || inst_f.is_a?(::ActiveRecord::Associations::CollectionProxy)
            inst_f.any? {|v| v.send(expression_method, cast_expression_value)}
          else
            inst_f.send(expression_method, cast_expression_value)
          end

          return result
        end

        private

        def evaluate(obj, method_names)
          result = obj
          method_names.each do |method|
            break unless result
            result = if result.is_a?(::Array)
              result.flatten.map { |r| r.send(method) }
            elsif result.is_a?(::ActiveRecord::Associations::CollectionProxy)
              result.map { |r| r.send(method) }
            else
              result.send(method)
            end
          end
          result
        end

        def cast_expression_value
          case expression_value_type
          when 'integer', 'float'
            expression_value.to_f
          when 'date'
            expression_value.to_date
          when 'boolean'
            ['1' 'true', 'yes', 't', 'y'].include?(expression_value)
          else
            expression_value
          end
        end

        def self.configure_renaming_for(schema)
          Dynamic::Schema.configure_renaming(
            attribute_name: {
              schema.reserved::Transaction::ApplicableAmount::Condition => {
                :yaml_array => [
                  :instance_field,
                ],
              }
            }
          )
        end
      end

    end
  end
end
