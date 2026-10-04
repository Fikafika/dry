class Crm
  module MailDropdown
    extend ActiveSupport::Concern
    include Protocol::DropdownItem

    def dropdown_item_for_mail_hosting_default_association(record, param = {}, show_icon = true)
      dropdown_item_for_protocol('mailto', '', param, show_icon).on(:click) do |event|

        yield if block_given?

        mail_hosting_feature = 'Dynamic::MailHosting::Feature'.constantize

        default_associations_fields = {
          recipients: mail_hosting_feature.default_recipient_association_name,
          cc: mail_hosting_feature.default_cc_association_name,
          bcc: mail_hosting_feature.default_cci_association_name
        }

        record.class.values_for_protocol(record.id, 'mailto', default_associations_fields.values) do |mailto_values|

          default_associations_fields.each do |method_name, association_name|
            Crm::MailEditor.send("#{method_name}=".to_sym, mailto_values[association_name].join(','))
          end

        end
      end
    end
  end
end