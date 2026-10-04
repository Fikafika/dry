module Notification
  module Item

    class Base < HyperComponent
      include Helpers

      param :record
      param :layout, default: 'list-group-item'
      param :duration, default: 5
      param :area, default: nil

      collect_other_params_as :other_params

      render { content }

      def content
        observe record
        case layout
        when 'list-group-item'
          list_group_item
        when 'toast'
          toast
        end
      end

      after_mount do
        if layout == 'toast'
          self.jq_node.on('hidden.bs.toast') do
            mark_as_shown
          end
        end
      end

      after_render do
        if layout == 'toast'
          if self.jq_node.has_class?('show')
            autohide
          else
            self.jq_node.toast(record.marked_as_shown ? 'hide' : 'show')
          end
        end
      end

      def list_group_item
        DIV(key: "notification-item-#{record.id}", class: 'list-group-item p-0') do
          DIV(class: 'card border-0', style: {flexDirection: 'row'}) do
            DIV(class: 'bg-light-yiq text-center p-4', style: {  width: '10%', minWidth: '100px' }) do
              I(class: "fa fa-#{icon} fa-3x"){}
            end
            DIV(class: 'card-body') do
              DIV(class: 'card-title d-flex flex-row') do
                DIV(class: 'flex-grow-1') do
                  H5(dangerously_set_inner_HTML: { __html: title }){}
                end
                DIV(class: 'text-muted text-nowrap') do
                  created_at
                end
              end
              body
              errors
              progress
            end
          end
        end
      end

      def toast
        DIV(key: "notification-toast-#{record.id}", class: 'toast', role: 'alert', 'aria-live': "assertive", 'aria-atomic': "true", "data-autohide": !keep_visible?, "data-delay": (duration * 1000)) do
          DIV(class: 'toast-header', style: {minWidth: '300px'}) do
            I(class: "fa fa-#{icon} mr-2"){}
            STRONG(class: 'flex-grow-1') do
              title
            end
            BUTTON(type: 'button', class: 'ml-2 mb-1 close', "data-dismiss": "toast", "aria-label": I18n.t('shared.close')) do
              SPAN("aria-hidden": true, dangerously_set_inner_HTML: { __html: '&times;' })
            end.on(:click) do |e|
              record.update(marked_as_read: true) do
                self.jq_node.toast('hide')
              end
            end
          end
          DIV(class: 'toast-body') do
            body
            errors
            progress
          end
        end
      end

      def icon
        record.icon || 'comment-alt'
      end

      def title
        record.title
      end

      def body
        if record.body.present?
          P(dangerously_set_inner_HTML: { __html: record.body })
        end
      end

      def errors
        return unless record.data_errors.present?
        ErrorMessage(errors: record.data_errors)
      end

      def progress
        if record.state
          case record.state
          when 'running', 'suspended'
            progress_bar
          else
            state
          end
        end
      end

      def progress_bar
        DIV(class: '') do
          DIV(class: 'd-flex flex-wrap') do
            ProgressBar(
              event: record.to_progress_event,
              info: record.progress_info,
              class: 'flex-grow-1 align-self-center',
              indeterminate: record.indeterminate?,
            )
            if record.state != 'finished'
              if record.can_suspend
                DIV(class: 'ml-2') do
                  suspend_btn
                end
              end
              if record.can_cancel
                DIV(class: 'ml-2') do
                  cancel_btn
                end
              end
            end
          end
        end
      end

      def state
        DIV(class: 'd-flex flex-wrap', style: {rowGap: '1rem'}) do
          DIV(class: 'align-self-center mr-auto') do
            if record.final_state
              SPAN { record.human_attribute_value(:final_state) }
            else
              SPAN { record.human_attribute_value(:state) }
            end
            explaination
          end
          if record.state != 'finished'
            if record.can_cancel
              DIV(class: 'ml-2') do
                cancel_btn
              end
            end
          else
            case record.final_state
            when 'succeeded'
              actions_for_succeeded
            when 'failed'
              actions_for_failed
              if record.can_retry
                retry_btn
              end
            when 'canceled'
              actions_for_canceled
              if record.can_retry
                retry_btn
              end
            end
          end
        end
      end

      def suspend_btn
        if record.state == 'suspended'
          Button(action: 'continue', icon: 'play', record: record)
        else
          Button(action: 'suspend', icon: 'pause', record: record)
        end
      end

      def cancel_btn
        Button(action: 'cancel', icon: 'times', record: record)
      end

      def close_btn
        return
        Button(action: 'retry', icon: 'redo', variant: 'transparent-light-yiq', record: record)
      end

      def retry_btn
        Button(action: 'retry', icon: 'redo', record: record)
      end

      def actions_for_succeeded
        # can be redefined
      end

      def actions_for_failed
        # can be redefined
      end

      def actions_for_canceled
        # can be redefined
      end

      def explaination
        # can be redefined
      end

      def keep_visible?
        duration.nil? || record.state == 'running'
      end

      def autohide
        if keep_visible_changed? && !keep_visible?
          $window.after(duration) do
            self.jq_node.toast('hide') if self.mounted?
          end
        end
      end

      def keep_visible_changed?
        if !@previous_keep_visible.nil? && @previous_keep_visible != keep_visible?
          @previous_keep_visible = keep_visible?
          return true
        else
          @previous_keep_visible = keep_visible?
          return false
        end
      end

      def mark_as_shown
        area&.mark_as_shown(record)
      end

      def created_at
        f = record.created_at&.to_s&.start_with?(today) ? :time_of_day : :date_time
        I18n.l(record.created_at, format: f)
      end

      def today
        Time.now.strftime('%Y-%m-%d')
      end

    end

    def self.klass_from(record)
      return Base unless record.klass_name
      "::Notification::Item::#{record.klass_name}".safe_constantize || Base
    end

  end

end

