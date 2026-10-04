# backtick_javascript: true

module Notification
  class Panel < HyperComponent
    include Notification::Helpers

    render { content }

    after_update do
      unless modal_initialized?
        self.jq_node.on('hidden.bs.modal') do
          @show = false
          mutate
        end
      end
      self.jq_node.modal(@show ? 'show' : 'hide')
    end

    def content
      return DIV() if never_shown?
      @shown = true
      DIV(class: 'modal fade', style: {zIndex: 1049}) do # z-index under right panel
        DIV(class: 'modal-dialog modal-lg modal-dialog-scrollable') do
          DIV(class: 'modal-content') do
            DIV(class: 'modal-header') do
              DIV(class: 'modal-title') do
                H5 do
                  I18n.t('notifications.panel_title')
                end
              end
              BUTTON(type: "button", class: 'close', 'data-dismiss': "modal") do
                SPAN(dangerously_set_inner_HTML: { __html: '&times;' })
              end
            end
            DIV(class: 'modal-body p-0') do
              if @show
                List()
              end
            end
            DIV(class: 'modal-footer') do
              BUTTON(type: "button", class: 'btn btn-primary', 'data-dismiss': "modal") do
                I18n.t('notifications.mark_all_as_read')
              end.on(:click) do |e|
                e.prevent_default
                mutate @show = false
                notification_klass.mark_all_as_read.then do
                  @show = true
                  hide
                end
              end
            end
          end
        end
      end
    end

    before_render do
      store_instance
    end

    def store_instance
      @@instance ||= {}
      @@instance[schema_name] = self
    end

    def self.instance
      @@instance ||= {}
      @@instance[schema_name]
    end

    def toggle
      mutate @show = !@show
    end

    def hide
      self.jq_node.modal('hide')
      ::Element.find('.toast').toast('hide')
    end

    def modal_initialized?
      @shown && !!`(#{self.jq_node.to_n}.data('bs.modal') !== undefined)`
    end

    def never_shown?
      !@show && !@shown
    end

  end

end
