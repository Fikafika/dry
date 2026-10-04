module Notification
  module Item
    module DocGen
      class Generation < ::Notification::Item::Base
        include Hyperstack::Router::Helpers
        include ::Router::Resources
        include ::Crm::Routes::Helpers

        render { content }

        def icon
          record.icon || 'file-invoice'
        end

        def actions_for_succeeded
          DIV(class: 'd-flex flex-row ml-auto') do
            if download_path
              DIV(class: 'ml-2') do
                download_btn
              end
            end
            if attached_record&.loaded?
              DIV(class: 'ml-2') do
                open_sheet_btn
              end
            end
          end
        end

        def download_btn
          A(class: 'btn btn-light', download: true, href: download_path) do
            I18n.t('shared.download')
          end
        end

        def download_path
          if active_storage_attachment
            active_storage_attachment.download_path
          else
            attached_record&.send(attachment).try(:download_path)
          end
        end

        def attached_record
          return unless record.data.is_a?(Hash) && record.data[:record_type] && record.data[:record_id]
          if !has_active_storage_attachment? && self.attachment.present?
            includes = {"#{attachment}": {include: {attachment: {include: {signed_id: 1, filename: 1}}}}}
          else
            includes = {}
          end
          @attached_record = record.data[:record_type].safe_constantize&.includes(includes)&.find(record.data[:record_id])
          observe @attached_record if @attached_record
          return @attached_record
        end

        def attachment
          record.data.is_a?(Hash) && record.data[:attachment]
        end

        def has_active_storage_attachment?
          record.data.is_a?(Hash) && record.data[:active_storage_attachment]
        end

        def active_storage_attachment
          return unless has_active_storage_attachment?
          @active_storage_attachment ||= ::HyperResource::ActiveStorage::Attachment.new(record.data[:active_storage_attachment])
        end

        def open_sheet_btn
          A(class: 'btn btn-light', href: edit_url(attached_record.class, attached_record.id), 'data-open-panel': 'right') do
            I18n.t('notifications.open_sheet')
          end
        end

      end
    end
  end
end
