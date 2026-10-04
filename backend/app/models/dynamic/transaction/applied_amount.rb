module Dynamic
  module Transaction
    module AppliedAmount
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      def self.after_included(klass, concern)
        proxify_concern(:__applied_amount__, klass, concern)
      end

      included do
        include Dynamic::Amount::Amount

        delegate *[
          :apply_amount_to_value,
          :register_owner,
          :recompute_owner_after_destroy,
          :recompute_owner,
          :recompute_owner?,
        ], to: :__applied_amount__

        before_destroy :register_owner, prepend: true
        after_commit :recompute_owner_after_destroy
        after_commit :recompute_owner, if: :recompute_owner?
      end

      class Proxy < Dynamic::Concern::Proxy

        def apply_amount_to_value(initial_value, current_value)
          value = case @record.applicability
          when 'on_base'
            initial_value
          when 'previous_operation'
            current_value
          end
          return @record.apply_amount(value)
        end

        def register_owner
          @record.instance_variable_set(:@owner, @record.owner)
        end

        def recompute_owner_after_destroy
          owner = @record.instance_variable_get(:@owner)
          @record.instance_variable_set(:@owner, nil)
          return unless owner
          owner.compute_amounts
          owner.save!
        end

        def recompute_owner
          @record.owner.compute_amounts
          @record.owner.save! if @record.owner.changed?
        end

        def recompute_owner?
          @record.owner && (@record.raw_value_previously_changed? || @record.percent_previously_changed?)
        end

      end

    end
  end
end
