class Form
  class Integrator
    class Store < ::HyperComponent
      include Hyperstack::State::Observable

      class << self

        DEFAULT_FONT_SIZE = 14
        DEFAULT_COLOR = '#000000'
        DEFAULT_IFRAME_HEIGHT = 600

        STATE_KEYS = [
          :source_record_type, :source_record_id,
          :target_record_type, :target_record_id,
          :iframe_height, :additional_params,
          :preview_url, :additional_params_hash,
          :code_font_size, :code_color,
          :code_bold, :code_italic, :loading_message_text
        ].freeze

        state_accessor(*STATE_KEYS)

        def update_settings(new_settings)
          mutate do
            new_settings.each do |key, value|
              setter = "#{key}="
              self.send(setter, value) if STATE_KEYS.include?(key.to_sym) && self.respond_to?(setter)
            end
          end
        end

        def reset
          mutate do
            STATE_KEYS.each do |key|
              self.send("#{key}=", nil)
            end
          end
        end

        def initialize_defaults
          mutate do
            self.iframe_height ||= DEFAULT_IFRAME_HEIGHT
            self.code_font_size ||= DEFAULT_FONT_SIZE
            self.code_color ||= DEFAULT_COLOR
            self.code_bold ||= false
            self.code_italic ||= false
            self.loading_message_text ||= ""
            self.additional_params ||= []
            self.additional_params_hash ||= {}
            self.preview_url ||= ""
          end
        end

        def get_loading_message_styles
          {
            fontSize: "#{code_font_size}px",
            color: code_color,
            fontWeight: code_bold ? 'bold' : 'normal',
            fontStyle: code_italic ? 'italic' : 'normal'
          }
        end
      end
    end
  end
end