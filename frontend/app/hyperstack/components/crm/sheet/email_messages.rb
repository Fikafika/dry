# Component to display messages for an Email with filtering tabs (All, To, Cc, Bcc)
class Crm
  class Sheet
    class EmailMessages < HyperComponent
      include Hyperstack::Router::Helpers

      param :email
      param :messages, default: []

      state_accessor :active_filter

      before_mount do
        self.active_filter = 'all'
      end

      render do
        DIV(class: 'email-messages-container') do
          # Sub-navigation tabs for message filters
          UL(class: 'nav nav-pills nav-fill mb-3', role: 'tablist') do
            LI(class: 'nav-item') do
              A(class: "nav-link #{'active' if active_filter == 'all'}", href: '#').on(:click) do |e|
                e.prevent_default
                self.active_filter = 'all'
              end.tap do
                I(class: 'fa fa-list mr-1')
                SPAN { I18n.t('mail_hosting.filters.all', default: 'Tout') }
              end
            end

            LI(class: 'nav-item') do
              A(class: "nav-link #{'active' if active_filter == 'to'}", href: '#').on(:click) do |e|
                e.prevent_default
                self.active_filter = 'to'
              end.tap do
                I(class: 'fa fa-arrow-right mr-1')
                SPAN { I18n.t('mail_hosting.filters.to', default: 'À') }
                SPAN(class: 'badge badge-light ml-1') { to_messages.count } if to_messages.any?
              end
            end

            LI(class: 'nav-item') do
              A(class: "nav-link #{'active' if active_filter == 'cc'}", href: '#').on(:click) do |e|
                e.prevent_default
                self.active_filter = 'cc'
              end.tap do
                I(class: 'fa fa-copy mr-1')
                SPAN { I18n.t('mail_hosting.filters.cc', default: 'Cc') }
                SPAN(class: 'badge badge-light ml-1') { cc_messages.count } if cc_messages.any?
              end
            end

            LI(class: 'nav-item') do
              A(class: "nav-link #{'active' if active_filter == 'bcc'}", href: '#').on(:click) do |e|
                e.prevent_default
                self.active_filter = 'bcc'
              end.tap do
                I(class: 'fa fa-eye-slash mr-1')
                SPAN { I18n.t('mail_hosting.filters.bcc', default: 'Cci') }
                SPAN(class: 'badge badge-light ml-1') { bcc_messages.count } if bcc_messages.any?
              end
            end
          end

          # Messages list
          DIV(class: 'messages-list') do
            if filtered_messages.any?
              filtered_messages.each do |message|
                render_message(message)
              end
            else
              DIV(class: 'alert alert-info') do
                I18n.t('mail_hosting.no_messages', default: 'No message')
              end
            end
          end
        end
      end

      def filtered_messages
        case active_filter
        when 'to'
          to_messages
        when 'cc'
          cc_messages
        when 'bcc'
          bcc_messages
        else
          messages
        end
      end

      def to_messages
        @to_messages ||= messages.select do |msg|
          msg_to_addresses = msg.try(:to)&.map { |e| e.try(:address) } || []
          msg_to_addresses.include?(email.try(:address))
        end
      end

      def cc_messages
        @cc_messages ||= messages.select do |msg|
          msg_cc_addresses = msg.try(:cc)&.map { |e| e.try(:address) } || []
          msg_cc_addresses.include?(email.try(:address))
        end
      end

      def bcc_messages
        @bcc_messages ||= messages.select do |msg|
          msg_bcc_addresses = msg.try(:bcc)&.map { |e| e.try(:address) } || []
          msg_bcc_addresses.include?(email.try(:address))
        end
      end

      def render_message(message)
        DIV(class: 'card mb-2') do
          DIV(class: 'card-body p-2') do
            DIV(class: 'd-flex justify-content-between align-items-start') do
              DIV(class: 'flex-grow-1') do
                H6(class: 'mb-1') do
                  message.try(:subject) || I18n.t('mail_hosting.no_subject', default: '(Sans objet)')
                end
                SMALL(class: 'text-muted d-block mb-1') do
                  SPAN(class: 'mr-2') do
                    STRONG { I18n.t('mail_hosting.from', default: 'De:') }
                    SPAN(class: 'ml-1') { message.try(:from)&.try(:address) }
                  end
                  SPAN do
                    I(class: 'fa fa-calendar mr-1')
                    format_date(message.try(:sent_at))
                  end
                end
                SMALL(class: 'text-muted') do
                  message.try(:text) || message.try(:body)
                end
              end
              DIV(class: 'ml-2') do
                Link("/schemas/#{schema_name}/klasses/#{message_klass_name}/#{message.id}/edit", class: 'btn btn-sm btn-outline-primary') do
                  I(class: 'fa fa-eye')
                end
              end
            end
          end
        end
      end

      def format_date(date)
        return '' unless date
        date.try(:strftime, '%d/%m/%Y %H:%M') || date.to_s
      end

      def schema_name
        email.class.name.split('::')[1].downcase
      end

      def message_klass_name
        messages.first&.class&.name&.split('::')&.last&.downcase || 'mailhostingmessage'
      end

    end
  end
end
