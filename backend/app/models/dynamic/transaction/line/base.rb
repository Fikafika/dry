module Dynamic
  module Transaction
    module Line
      module Base
        extend ActiveSupport::Concern
        extend Dynamic::Concern

        def self.after_included(klass, concern)
          proxify_concern(:__transaction_line__, klass, concern)
          klass.const.define_has_many_callback(:after_add, :sublines, :recompute_amount_from_association)
          klass.const.define_has_many_callback(:after_remove, :sublines, :recompute_amount_from_association)

          klass.const.define_has_many_callback(:after_add, :discounts, :recompute_amount_from_association)
          klass.const.define_has_many_callback(:after_remove, :discounts, :recompute_amount_from_association)

          klass.const.define_has_many_callback(:after_add, :fees, :recompute_amount_from_association)
          klass.const.define_has_many_callback(:after_remove, :fees, :recompute_amount_from_association)
        end

        included do
          delegate *[
            :copy_article_name_and_amount,
            :copy_article_lines_and_options,
            :gather_fees_and_discounts_attributes,
            :gather_fees_and_discounts_attributes?,
            :copy_article_infos?,
            :compute_quantity,
            :compute_amounts,
            :compute_fees_and_discounts,
            :update_sublines_quantity,
            :quantity_changed?,
            :update_transaction,
            :update_transaction?,
            :compute_discounts,
            :update_parent,
            :update_parent?,
            :recompute_amount_from_association,
            :update_from_associations,
            :update_from_associations?,
            :register_parent_and_owner,
          ], to: :__transaction_line__

          before_save :compute_quantity
          before_save :copy_article_name_and_amount, if: :copy_article_infos?
          before_save :gather_fees_and_discounts_attributes, if: :gather_fees_and_discounts_attributes?
          before_save :copy_article_lines_and_options, if: :copy_article_infos?
          before_save :compute_amounts
          before_update :update_sublines_quantity, if: :quantity_changed?

          before_destroy :register_parent_and_owner, prepend: true

          after_commit :update_parent, if: :update_parent?
          after_commit :update_from_associations, if: :update_from_associations?
          after_commit :update_transaction, if: :update_transaction?
        end

        class Proxy < Dynamic::Concern::Proxy

          attr_accessor :copy_articles

          def copy_article_name_and_amount
            @record.label = @record.article.name unless @record.label
            @record.vat_rate = @record.article.vat_rate
            @record.gross_unit_price = @record.article.gross_unit_price
            if @record.gross_unit_price && !@record.invoiced_quantity
              if @record.parent || @record.parent_id
                compute_quantity
              else
                @record.invoiced_quantity = 1
              end
            end
            self.copy_articles = true
          end

          # Create additional lines for article's options and fees with different vat_rate than article
          def copy_article_lines_and_options
            sublines_attrs = []
            last_pos = @other_attributes && @other_attributes[:vat_sublines_attributes] ? (@other_attributes[:vat_sublines_attributes].dig(-1, :position) || 0) : 0
            last_pos += 1

            @record.article.options.each do |o|
              attrs = {
                id: UUID7.generate,
                position: last_pos,
                label: o.name,
                vat_rate: o.vat_rate,
                gross_unit_price: o.gross_unit_price,
                invoiced_quantity: @record.invoiced_quantity,
              }
              attrs.merge!(type: "#{@record.class.module_parent.name}::TransactionLineInfo") unless o.gross_unit_price
              sublines_attrs << attrs
              last_pos += 1
            end

            @record.article.package_members.sort_by {|m| m.position }.each do |m|
              sublines_attrs << {
                article: m.target_article,
                position: last_pos,
                invoiced_quantity: (m.quantity || 0) * @record.invoiced_quantity,
                quantity_for_single_unit_of_parent_line: m.quantity,
                type: "#{@record.class.module_parent.name}::TransactionLineInfo",
              }
              last_pos += 1
            end

            if @other_attributes
              if @other_attributes[:discounts_attributes].any?
                discounts_attributes = @other_attributes[:discounts_attributes].map {|d| d.except(:target_amount)}
                discount_attributes.merge!(owner: @record)
                @record.discounts.build(discounts_attributes)
              end
              if @other_attributes[:fees_attributes].any?
                fees_attributes = @other_attributes[:fees_attributes].map {|d| d.except(:target_amount)}
                fees_attributes.merge!(owner: @record)
                @record.fees.build(@fees_attributes)
              end
            end

            @record.sublines.build(sublines_attrs)

            if @record.article.options.any?
              @record.build_parent(invoiced_quantity: 1, type: "#{@record.class.module_parent.name}::TransactionLineGroup", sublines: [@record])
            end

            self.copy_articles = false
          end

          def gather_fees_and_discounts_attributes
            @other_attributes = {fees_attributes: [], discounts_attributes: [], vat_sublines_attributes: []}
            rule_klass = @record.class.module_parent::R::Transaction::ApplicableAmount::Rule
            next_transaction_line_position = 0

            rules = rule_klass.where(target_id: @record&.article&.product_id).order(priority: :asc).all
            rules.each do |r|
              next unless r.is_valid?(@record)
              if r.amount.type == "#{@record.class.module_parent.name}::Fee" && !same_vat_rate?(r.amount.vat_rate, @record.vat_rate)
                @other_attributes[:vat_sublines_attributes] << {
                  target_amount: r.amount,
                  position: next_transaction_line_position,
                  label: "#{r.amount.name} - #{@record.label}",
                  vat_rate_id: r.amount.vat_rate_id,
                  invoiced_quantity: @record.invoiced_quantity,
                  type: "#{@record.class.module_parent.name}::TransactionLineVat",
                }
                next_transaction_line_position += 1
              else
                case r.amount.type.split('::').last
                when 'Fee'
                  @other_attributes[:fees_attributes] << {
                    owner: @record,
                    name: r.amount.name,
                    target_amount: r.amount,
                    percent: r.amount.percent,
                    raw_value: r.amount.raw_value,
                    position: r.priority,
                    applicability: r.applicability,
                  }
                when 'Discount'
                  @other_attributes[:discounts_attributes] << {
                    owner: @record,
                    name: r.amount.name,
                    target_amount: r.amount,
                    percent: r.amount.percent,
                    raw_value: r.amount.raw_value,
                    position: r.priority,
                    applicability: r.applicability,
                  }
                end
              end
            end
          end

          def same_vat_rate?(a, b)
            return a&.percent == b&.percent && a&.code == b&.code
          end

          def gather_fees_and_discounts_attributes?
            @record&.article&.product_id && copy_article_infos?
          end

          def copy_article_infos?
            self.copy_articles || (@record.new_record? && @record.article && @record.sublines.none? && !@record.gross_unit_price)
          end

          def compute_amounts
            if @record.gross_unit_price
              @record.net_unit_price = @record.gross_unit_price
              amount = 0
              @record.discounts.sort_by {|d| d.position}.each do |d|
                amount += d.apply_amount_to_value(@record.gross_unit_price, @record.gross_unit_price + amount)
              end
              @record.fees.sort_by {|f| f.position}.each do |f|
                amount += f.apply_amount_to_value(@record.gross_unit_price, @record.gross_unit_price + amount)
              end
              @record.amount_excluding_vat = (@record.net_unit_price * (@record.invoiced_quantity || 1) + amount).round(2)
              @record.vat_amount = compute_vat_amount
              @record.amount_including_vat = @record.amount_excluding_vat + @record.vat_amount
            else
              @record.net_unit_price = nil
              @record.amount_excluding_vat = nil
              @record.vat_amount = nil
              @record.amount_including_vat = nil
            end
          end

          def compute_quantity
            parent = @record.parent
            if !parent && @record.parent_id
              superklass_name = "#{@record.class.module_parent.name}::TransactionLine"
              parent = superklass_name.safe_constantize.find(@record.parent_id)
            end
            if parent && @record.gross_unit_price
              @record.quantity_for_single_unit_of_parent_line ||= 1
              @record.invoiced_quantity = (@record.parent.invoiced_quantity || 1) * @record.quantity_for_single_unit_of_parent_line
              @record.quantity_for_single_unit_of_parent_line ||= @record.invoiced_quantity
            end
          end

          def compute_vat_amount
            result = 0
            if @record.vat_rate
              value = @record.amount_excluding_vat * @record.vat_rate.percent
              result = value.round(2)
            end
            return result
          end

          def compute_fees_and_discounts
            result = {
              fees: normalize_amounts(@record.fees),
              discounts: normalize_amounts(@record.discounts),
            }

            result[:fees_amount] = result[:fees].inject(0) {|res, fee| res + fee[:computed_value]}
            result[:discounts_amount] = result[:discounts].inject(0) {|res, discount| res + discount[:computed_value]}

            @record.sublines.each do |s|
              next unless s.type.demodulize == 'TransactionLineVat'
              result[:fees_amounts] += s.net_unit_price
            end

            result[:fees_amount] *= @record.invoiced_quantity || 1
            result[:discounts_amount] *= @record.invoiced_quantity || 1

            return result
          end

          def compute_discounts
            r = compute_fees_and_discounts
            r ? r[:discounts_amount] : nil
          end

          def normalize_amounts(amounts)
            current_amount = @record.gross_unit_price || 0
            amounts.sort_by{|f| f.position }.map do |f|
              val = f.applicability == 'on_base' ? @record.gross_unit_price : current_amount
              computed_amount = f.apply_amount_to_value(@record.gross_unit_price, current_amount)
              current_amount += computed_amount
              {
                name: f.name,
                initial_value: val,
                computed_value: computed_amount,
                percent: f.percent,
                raw_value: f.raw_value,
                applicability: f.applicability,
              }
            end
          end

          def update_sublines_quantity
            @record.sublines.each do |s|
              s.update!(invoiced_quantity: (s.quantity_for_single_unit_of_parent_line || 1) * @record.invoiced_quantity)
            end
          end

          def quantity_changed?
            @record.invoiced_quantity_changed?
          end

          def update_transaction
            @record.owner_transaction.transaction_lines&.reload
            @record.owner_transaction.compute_amounts
            @record.instance_variable_set(:@owner_transaction, nil)
            @record.owner_transaction.save!
          end

          def update_transaction?
            return false if update_parent?
            return true if @record.instance_variable_get(:@owner_transaction)
            return @record.owner_transaction && amount_did_changed?
          end

          def amount_did_changed?
            (['gross_unit_price', 'invoiced_quantity', 'amount_excluding_vat', 'amount_including_vat'] & @record.previous_changes.keys).any?
          end

          def update_parent
            parent = @record.parent || @record.instance_variable_get(:@parent)
            if parent
              parent.sublines&.reload
              parent.compute_amounts
              @record.instance_variable_set(:@parent, nil)
              parent.save! if @record.parent.changed?
            elsif @record.previous_changes['parent_id']
              prt_id = @record.previous_changes['parent_id'].first || @record.previous_changes['parent_id'].last
              prt = @record.class.reflect_on_association(:parent).klass.find(prt_id)
              return unless prt
              prt.compute_amounts
              prt.save! if prt.changed?
            end
          end

          def update_parent?
            return true if @record.instance_variable_get(:@parent)
            return true if @record.parent_id_previously_changed?
            return @record.parent_id && amount_did_changed?
          end

          def register_parent_and_owner
            @record.instance_variable_set(:@parent, @record.parent)
            @record.instance_variable_set(:@owner_transaction, @record.owner_transaction)
          end

          def update_from_associations
            @record.instance_variable_set(:@must_save, nil)
            @record.compute_amounts
            @record.save! if @record.changed?
          end

          def update_from_associations?
            @record.instance_variable_get(:@must_save)
          end

          def recompute_amount_from_association(record)
            if @record.persisted?
              @record.instance_variable_set(:@must_save, !@record.changed?)
            end
          end

        end
      end
    end
  end
end
