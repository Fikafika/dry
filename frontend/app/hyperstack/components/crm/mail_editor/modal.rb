class Crm::MailEditor::Modal < ::Modal
  include Crm::DataOpenPanel

  param :suggestions
  param :crm_api_url, default: ''
  param :crm_schema_name, default: ''
  param :default_value, default: {}
  param :mailto
  param :attachment_files, type: Array, default: []
  param :cc, default: ''
  param :bcc, default: ''
  param :templating_params
  param :search_templating_variables, default: []
  param :open_viewer, default: false
  param :message_id, default: nil
  param :community_id, default: nil

  disable_auto_unmount_instance_variables

  after_mount do
    self.jq_node.modal(show ? 'show' : 'hide')
  end

  def title
  end

  def footer
  end

  def panel_param(side)
    "#{side[0]}p"
  end

  def modal
    DIV(id: 'mail-editor-modal', class: "modal px-0", role: 'dialog', 'data-dismiss': false, 'data-backdrop': false) do
      DIV(class: "modal-dialog modal-lg", role: 'document') do
        DIV(class: 'modal-content border-0') do
          ns = normalize_suggestions(suggestions)

          UneekMessageEditor(
            forceMaximize: false,
            defaultFiles: attachment_files,
            apiUrl: "#{uneek_mail_host}/api",
            crmContactFormApiUrl: "#{crm_api_url.to_s.sub(%r{/$}, '')}/d/#{crm_schema_name}/contacts",
            onOpenContactForm: Proc.new { |path, context| open_panel('left', path) },
            loginUrl: "#{uneek_mail_host}/?sidepanel=settings",
            aiAssistantUrl: "#{uneek_ai_assistant_host}",
            templatingParams: templating_params.to_n,
            searchTemplatingVariables: search_templating_variables,
            defaultValue: {
              formated_recipients: {
                to: format_recipients(mailto),
                cc: format_recipients(cc),
                bcc: format_recipients(bcc)
              }
            }.to_n,
            emailSuggestions: ns,
            readOnly: open_viewer,
            messageId: message_id,
            communityId: community_id,
            onClose: Proc.new { close }
          )
        end
      end
    end
  end

  def uneek_mail_host
    ENV['UNEEK_MAIL_APP_PROTOCOL'] + '://' + ENV['UNEEK_MAIL_APP_HOST']
  end

  def uneek_ai_assistant_host
    ENV['UNEEK_AI_ASSISTANT_PROTOCOL'] + '://' + ENV['UNEEK_AI_ASSISTANT_HOST']
  end

  def format_recipients(recipient_string)
    return [] unless recipient_string.present?

    recipients = []
    recipient_string.split(",").each do |mail|
      recipients << {email: mail.strip, username: ""} if mail.strip.present?
    end

    recipients
  end

  # Normalize `suggestions` so that it is always either:
  # - a Proc (e.g., for dynamic client-side suggestions) left as is,
  # - or an array of objects { email: ‘x’, username: ‘y’ }.
  def normalize_suggestions(suggestions)
    return [] if suggestions.nil?

    # If a proc or callable is provided, keep it as is (the JS side can use it).
    return suggestions if suggestions.respond_to?(:call)

    arr = suggestions.is_a?(Array) ? suggestions : [suggestions]
    arr.map do |item|
      case item
      when String
        email = item.to_s.strip
        email.present? ? { email: email, username: "", tag: "" } : nil
      when Hash
        # Ensure the expected keys including tag
        {
          email: (item[:email] || item['email']).to_s,
          username: (item[:username] || item['username'] || "").to_s,
          tag: (item[:tag] || item['tag'] || "").to_s
        }
      else
        # Subject: reply to: email / username / tag
        if item.respond_to?(:email)
          {
            email: item.email.to_s,
            username: (item.respond_to?(:username) ? item.username.to_s : ""),
            tag: (item.respond_to?(:tag) ? item.tag.to_s : "")
          }
        else
          nil
        end
      end
    end.compact
  end
end