# backtick_javascript: true
require 'components/wait_for_completed_jobs'

class Crm
  class Sheet
    class Menu < ::Crm::Base
      include WaitForCompletedJobs
      include ::Router::Resources

      include Crm::MailDropdown

      param :record, default: nil
      collect_other_params_as :other_params

      render { content }

      def content
        observe record
        DIV(id: menu_id, class: "dropdown #{other_params[:className]}") do
          A(
            href: '#',
            class: 'btn btn-transparent-light-yiq',
            role: 'button',
            'data-toggle': 'dropdown',
            'aria-haspopup': true,
            'aria-expanded': false
          ) do
            I(class: 'fa fa-ellipsis-v'){}
          end
          DIV(class: 'dropdown-menu', 'aria-labelledby': menu_id) do
            menu_items
          end
        end
      end

      def menu_id
        other_params[:id] || "record-menu" # TODO make uniq
      end

      def menu_items
        if record && record.is_a?(Dynamic::Record::Base) && !record.new_record?
          send_mail_using_mailhosting_default_recipients if can_send_email_using_mailhosting_default_recipients?
          vcard_link if show_vcard_link?
          doc_gen_link if show_doc_gen_link?
          copy_run_link if show_copy_run_link?
          versions_link
        end
        permissions_link if User.current&.admin?(schema.name)
        delete_record_link
      end

      def copy_run_link
        A(href: '#', class: 'dropdown-item') do
          I(class: 'fas fa-copy fa-fw pr-2')
          I18n.t('crm.copy.context_menu.run')
        end.on(:click) do |event|
          event.prevent_default
          ::Element.find('#copy-run-modal').trigger('show.dynamo.modal', [{ record: record }])
        end
      end

      def show_copy_run_link?
        return false unless schema.has_feature_enabled?('Dynamic::Copy::Feature')
        return User.current.can_create?(schema.absolute_reserved_klass_name('Copy::Setting'))
      end


      def doc_gen_link
        A(href: '#', class: 'dropdown-item') do
          I18n.t('doc_gen.generate')
        end.on(:click) do |event|
          event.prevent_default
          ::Element.find('#docgen-modal').trigger('show.dynamo.modal', [{ record: record }])
        end
      end

      def show_doc_gen_link?
        return false unless schema.has_feature_enabled?('Dynamic::DocGen::Feature')
        return User.current.can_read?(schema.absolute_reserved_klass_name('DocGen::Template'), schema: schema)
      end

      def vcard_link
        url = record.class.member_path(id: record.id).gsub(/\.json$/, '.vcf')
        A(href: url, class: 'dropdown-item') do
          DIV(class: 'mb-2') do
            I18n.t('vcard.download')
          end
          QRCode(str: "#{`window.location.origin`}#{url}" , class: 'mb-2')
        end
      end

      def show_vcard_link?
        return false unless schema.has_feature_enabled?('Dynamic::Vcard::Feature')
        return false unless record.is_a?(Dynamic::Vcard::Base)
        vcard_feature_id = schema.features.detect {|f| f.name == 'Dynamic::Vcard::Feature'}&.id
        return !!vcard_feature_id
      end

      def versions_link
        return unless User.current.admin?(request.params[:schema])
        Link(url_for(record: record, action: 'versions'), class: 'dropdown-item', 'data-open-panel' => 'opposite') do
          I18n.t('crm.sheet.menu.versions')
        end
      end

      def permissions_link
        Link(link_for_permission, class: "dropdown-item", "data-open-panel": 'opposite') do
          UneekPermission::Rule.model_name.human
        end
      end

      def link_for_permission
        "/crm/#{self.schema.name.underscore}/table/#{record.class.name.demodulize.underscore.pluralize}/#{record.id}/rules"
      end

      def delete_record_link
        A(href: '#', class: 'dropdown-item') do
          I18n.t('shared.delete')
        end.on(:click) do |event|
          event.prevent_default
          Modal.confirm(title: I18n.t('shared.delete')) do
            record.destroy(wait_for_completed_jobs_options).then do |response|
              if response[:success]
                delete_success
              end
            end
          end
        end
      end

      def delete_success
        self.jq_node.closest('.crm-sheet').trigger(:reload_after_destroy)
      end

      def can_send_email_using_mailhosting_default_recipients?
        return false unless record
        return false unless record.class.parent.feature_enabled?('Dynamic::MailHosting::Feature')
        mail_hosting_feature_id = schema.features.detect {|f| f.name == 'Dynamic::MailHosting::Feature'}&.id
        return false unless mail_hosting_feature_id
        return false unless User.current.can_read?('Dynamic::Schema::Feature', schema: schema, id: mail_hosting_feature_id)

        record.class.has_mailhosting_associations?
      end

      def send_mail_using_mailhosting_default_recipients
        dropdown_item_for_mail_hosting_default_association(record, {}, false)
      end

    end
  end
end
