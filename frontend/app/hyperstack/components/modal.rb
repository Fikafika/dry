# backtick_javascript: true

class Modal < HyperComponent
  include Hyperstack::Router::Helpers

  collect_other_params_as :other_params

  class << self

    def confirm(options = {})
      `dataConfirmModal.confirm(#{
          confirm_defaults.merge(options).merge({
            onConfirm: Proc.new{ yield }
          }).to_n
      })`
    end

    def confirm_defaults
      {
        title: I18n.t('shared.confirm'),
        text: I18n.t('shared.ask_for_confirmation'),
        commit: I18n.t('shared._yes'),
        commitClass: 'btn-primary',
        cancel: I18n.t('shared._no'),
        cancelClass: 'btn-default',
        zIndex: 1050,
        modalClass: 'modal-center',
      }
    end

  end

  fires :cancel
  fires :confirm
  fires :close

  after_update do
    self.jq_node.modal(show ? 'show' : 'hide')
  end

  after_mount do
    self.jq_node.on('hidden.bs.modal') do |event|
      after(0.1) do
        cancel
        mutate
      end
    end

    self.jq_node.on('show.bs.modal') do |event, *event_params|
      unless @show
        @show = true
        @event = event
        @event_params = event_params
        mutate
      end
    end

    self.jq_node.on('show.dynamo.modal') do |event, *event_params|
      @show = true
      @event = event
      @event_params = event_params
      mutate
    end
  end

  render { content }

  def content
    if portal
      Portal(id: portal, parentSelector: '.router-top-level') do
        modal
      end
    else
      modal
    end
  end

  def portal
    other_params[:portal]
  end

  def modal
    DIV(id: other_params[:id], class: "modal px-0", role: 'dialog', 'data-dismiss': 'modal') do
      next unless show
      init

      DIV(class: "modal-dialog modal-#{size} shadow-sm", role: 'document') do
        DIV(class: 'modal-content') do
          if title.present?
            DIV(class: 'modal-header') do
              H5(class: 'modal-title') do
                title
              end
              BUTTON(class: "close", type: "button", "data-dimiss": "modal", "aria-label": 'Close') do
                SPAN("aria-hidden": true, dangerously_set_inner_HTML: {__html: '&times;'})
              end.on(:click) do |event|
                cancel
              end
            end
          end
          DIV(class: "modal-body") do
            body
          end
          DIV(class:"modal-footer") do
            footer
          end
        end
      end
    end
  end

  def show
    other_params.has_key?(:show) ? other_params[:show] : @show
  end

  def init
  end

  def title
  end

  def body
  end

  def footer
    BUTTON(class:"btn bg-light mr-2", type:"button") do
      cancel_btn_text
    end.on(:click) do |event|
      cancel
    end
    BUTTON(class:"btn btn-primary", type:"button", disabled: !confirm_enabled?) do
      confirm_btn_text
    end.on(:click) do |event|
      confirm
    end
  end

  def confirm_enabled?
    true
  end

  def cancel
    cancel!
    close
  end

  def confirm
    confirm!
    close
  end

  def close
    @show = false
    @event = nil
    @event_params = nil
    self.jq_node.modal('hide')
    after do
      close!
    end
  end

  def cancel_btn_text
    I18n.t('shared.cancel')
  end

  def confirm_btn_text
    I18n.t('shared.confirm')
  end

  def size
    other_params[:size] || default_size
  end

private

  def default_size
    'sm'
  end

end
