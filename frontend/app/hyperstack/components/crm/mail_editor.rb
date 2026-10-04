# backtick_javascript: true

class Crm
  class MailEditor < Base

    class << self
      def recipients=(value)
        Store.recipients = value
      end

      def cc=(value)
        Store.cc = value
      end

      def bcc=(value)
        Store.bcc = value
      end

      def update_context(klass, id)
        Store.context = {klass: klass, id: id}
      end

      def open_from(link_element)

        if link_element
          record_parent = link_element.closest('.record-mailto')

          if record_parent.length > 0 && record_parent.data('recordclass')
            record_klass = record_parent.data('recordclass').safe_constantize
            record_id = record_parent.data('recordid')
            update_context(record_klass, record_id)
          end
        end

        Store.open_editor = true
      end

      def open_for_viewing(record)
        return unless record

        Store.recipients = ''
        Store.cc = ''
        Store.bcc = ''
        Store.default_value = {}
        Store.open_viewer = true
        Store.message_id = record.id
        Store.open_editor = true
      end

      def add_attachments(attachments)

        if (attachments.respond_to?(:map))
          file_urls = attachments.map(&:download_path)
        elsif (attachments.respond_to?(:download_path))
          file_urls = [attachments.download_path]
        else
          file_urls = []
        end

        unless file_urls.empty? || !file_urls.is_a?(Array)
          Store.attachment_files = file_urls
        end
      end
    end

    before_mount do
      Store.attachment_files = []
    end

    after_mount do
      Store.context = {}
    end

    render do
      if Store.open_editor
        Modal(
          suggestions: Proc.new{|value| suggestions(value)},
          crm_schema_name: schema.permalink,
          default_value: Store.default_value,
          templating_params: templating_params,
          mailto: Store.recipients,
          cc: Store.cc,
          bcc: Store.bcc,
          attachment_files: Store.attachment_files,
          search_templating_variables: search_templating_variables,
          open_viewer: Store.open_viewer,
          message_id: Store.message_id,
          community_id: App.current_community&.uneek_sso_uuid,
          show: true
        ).on(:close) do
          close_editor
        end
      end
    end

    def suggestions(value)
      return [] unless email_klass
      HttpWithCrossDomain.get("#{email_klass.api_path}?select2=true&term=#{value}&include%5Bowner%5D=1").then{|res|
        if res.json[:results]&.length > 0
          results = res.json[:results].map do |r|
            owner = r.dig(:record, :owner) || {}
            owner_name = owner[:polymorphic_name].to_s

            {
              username: owner_name,
              email: r.dig(:record, :address),
              tag: r.dig(:record, :tag)
            }
          end
          results
        else
          []
        end
      }.to_n
    end

    def feature

      return @feature if @feature_loaded

      @feature_loaded = true
      @feature = feature_klass&.const
    end

    def templating_params
      if !Store.context[:klass] || !Store.context[:id]
        {}
      else
        {
          baseUrl: "#{ENV['APP_PATH_PREFIX']}",
          uri: "/api/variables/d/#{schema.permalink}",
          query: {
            schema_name: schema.name,
            context: {
              record: {
                klass: Store.context[:klass]&.name&.split('::')&.last,
                id: Store.context[:id],
              }
            }
          },
          subject: "record",
          setVariableInQuery: set_variables_in_query
        }
      end
    end

    def search_templating_variables
      if !Store.context[:klass] || !Store.context[:id]
        []
      else
        Store.context[:klass].protocols_for_attributes.keys
      end
    end

    def set_variables_in_query(query_params, variables)
      Proc.new do |query_params, variables|
        variables = [] unless variables.present?
        `#{query_params}['formula']=#{variables.to_n}`
      end
    end

    def close_editor
      Store.context = {}
      Store.open_editor = false
      Store.recipients = ''
      Store.cc = ''
      Store.bcc = ''
      Store.attachment_files = []
      Store.open_viewer = false
      Store.message_id = nil
    end

    private

    def feature_klass
      @feature_klass ||= schema.features.detect{|f| f.name == "Dynamic::MailHosting::Feature"}
    end

    def email_klass
      @email_klass ||= schema.const.mailhosting_email_klass
    end
  end
end
