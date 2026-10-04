require 'components/number_helper'

class Crm
  module TransactionLine
    class Summary < HyperComponent
      include ::NumberHelper

      param :record_id
      param :record_klass
      param :lines_association
      param :amount_including_vat_attribute
      param :amount_excluding_vat_attribute
      param :vat_breakdown_attribute
      param :discount_and_fee_summary_attribute
      param :currency_association

      collect_other_params_as :other_params

      track_changes :record_id

      render do
        next unless record&.loaded?
        amounts = [amount_excluding_vat_attribute, amount_including_vat_attribute].compact

        if amounts.any?
          discounts_and_fees = record.send(discount_and_fee_summary_attribute)
          TABLE(class: "table table-sm table-bordered float-right w-auto") do
            TBODY do
              if discounts_and_fees[:discounts_amount]
                TR do
                  TH(class: 'bg-light-yiq') do
                    I18n.t('crm.transaction_line.summary.discounts_amount')
                  end
                  TD(class: 'text-right') do
                    number_to_currency(discounts_and_fees[:discounts_amount], currency: currency)
                  end
                end
              end
              if discounts_and_fees[:fees_amount]
                TR do
                  TH(class: 'bg-light-yiq') do
                    I18n.t('crm.transaction_line.summary.fees_amount')
                  end
                  TD(class: 'text-right') do
                    number_to_currency(discounts_and_fees[:fees_amount], currency: currency)
                  end
                end
              end
              amounts.each do |attr|
                TR do
                  TH(class: 'bg-light-yiq') do
                    record.class.human_attribute_name(attr)
                  end
                  TD(class: 'text-right') do
                    number_to_currency(record.send(attr), currency: currency)
                  end
                end
              end
            end
          end
        end

        if vat_breakdown_attribute
          breakdown = record.send(vat_breakdown_attribute)
          if breakdown&.any? && breakdown.is_a?(::Array)
            TABLE(class: "table table-sm table-bordered") do
              THEAD(class: 'bg-light-yiq') do
                TR() do
                  breakdown_cols.each do |col|
                    TH do
                      I18n.t("crm.transaction_line.summary.#{col}")
                    end
                  end
                end
              end
              TBODY do
                breakdown.each_with_index do |value, i|
                  is_total_row = i == breakdown.length - 1 && value['percent'].nil?
                  TR(class: "#{'font-weight-bold' if is_total_row}") do
                    breakdown_cols.each do |col|
                      if is_total_row && col == 'percent'
                        TD(class: "bg-light-yiq") do
                          I18n.t('crm.transaction_line.summary.total')
                        end
                      else
                        f = col_format_type[col]
                        TD(class: "#{'text-right' if f == 'currency'}") do
                          if col == 'percent'
                            DIV(class: 'pr-2 d-flex justify-content-between') do
                              DIV() do
                                UneekFormatting::Dynamic::AttributeFormatter.send("number_to_#{f}", value[col], format_options[f])
                              end
                              SMALL(dangerously_set_inner_HTML: { __html: value['hint'] })
                            end
                          elsif f
                            send("number_to_#{f}", value[col], format_options[f]) || I18n.t('shared.none')
                          else
                            value[col]
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end

      end

      private

      def css_class
        other_params[:className]
      end

      def record
        return unless record_klass && record_id
        record_klass.update_cache(['find']) if record_id_changed?
        return observe record_klass.includes(record_includes).find(record_id)
      end

      def record_includes
        result = {}
        if vat_breakdown_attribute
          result[vat_breakdown_attribute] = 1
        end
        if discount_and_fee_summary_attribute
          result[discount_and_fee_summary_attribute] = 1
        end
        if lines_association
          result[lines_association] = 1
        end
        if currency_association
          result[currency_association] = 1
        end
        return result
      end

      def breakdown_cols
        ['percent', 'excluding_vat', 'vat_amount', 'including_vat']
      end

      def col_format_type
        {
          'percent' => 'x100_percentage',
          'excluding_vat' => 'currency',
          'vat_amount' => 'currency',
          'including_vat' => 'currency',
        }
      end

      def format_options
        {
          'x100_percentage' => { strip_insignificant_zero: true, precision: 2 },
          'currency' => { currency: currency },
        }
      end

      def currency
        record.send(currency_association)&.iso_code
      end

    end
  end
end
