class Crm
  class MailEditor < Base
    class Store
      include Hyperstack::State::Observable

      class << self
        state_accessor :context, :recipients, :open_editor, :cc, :bcc, :default_value, :open_viewer, :message_id

        attr_accessor :attachment_files

        def initialize
          @recipients = ''
          @context = {}
          @open_editor = false
          @cc = ''
          @bcc = ''
          @default_value = {}
          @open_viewer = false
          @message_id = nil
        end
      end
    end
  end
end