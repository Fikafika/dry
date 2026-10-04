# backtick_javascript: true

class Crm
  class Forms < HyperComponent
    include Hyperstack::Router::Helpers
    include Router::Resources

    render(DIV) { routes }

    before_mount do
      @authenticate = false
    end

    def routes
      Resources("/crm/:schema_id/forms(/:form_id)", authentication: @authenticate) do
        with_schema_loaded_and_dynamic_form_received do
          layout_elements_or_message do
            render_elements
          end
        end
      end
    end

    def with_schema_loaded_and_dynamic_form_received
      # schema must have constant loaded
      # dynamic_form must be received but can have a unauthorized status_code at this point
      return unless schema && dynamic_form
      yield
    end

    def schema
      return @schema if @schema
      @schema_promise ||= Dynamic::Schema.load(request.params[:schema_id]) do |s|
        @schema = s
        mutate
      end
    end

    def render_elements
      DIV(class: 'mt-3') do
        Form(
          schema_id: request.params[:schema_id],
          dynamic_form_id: request.params[:form_id],
          source_record_id: request.params[:source_record_id],
          source_record_type: request.params[:source_record_type],
          target_record_id: request.params[:target_record_id],
          target_record_type: request.params[:target_record_type],
          dynamic_form_options: {
            submission_automatically_saved_on_load: true,
          }.merge(request.params[:options] || {}),
          params: request.params[:params],
          render_edit_record_links: false,
          class: 'container-fluid'
        ) do
          Form::Footer()
          Crm::Forms::Message()
        end.on(:start) do
          if in_iframe?
            dismiss_loading_message
          end
        end.on(:load_error) do |status|
          if status == 401 && @authenticate == false
            mutate @authenticate = true
          end
        end.on(:loaded) do |form|
          if in_iframe?
            resize_iframe
          else
            change_window_title
          end
          if dynamic_form.auto_submission
            auto_submit(form)
          end
          execute_on_load_script
        end.on(:save_as_draft) do
          add_restore_to_request_params
        end.on(:success) do
          post_message({ iframeFormSubmitted: 'success' }) if in_iframe?
          Form.current.reset
        end.on(:finish) do
          redirect_to_final_url if dynamic_form.final_redirect_url
        end
      end
    end

    def redirect_to_final_url
      url = dynamic_form.final_redirect_url
      if !url.start_with?('http://') && !url.start_with?('https://') && !url.start_with?('/')
        url = "http://#{url}"
      end
      JS.call(:open, url, '_parent')
    end

    def layout_elements_or_message
      return yield unless dynamic_form.forbidden?
      return render_message(I18n.t("crm.forms.unattainable")) if dynamic_form.evaluate_access_with_formula
      current_time = Time.current
      if dynamic_form.start_date && current_time < Time.parse(dynamic_form.start_date)
        render_message(dynamic_form.text_before_start_date)
      elsif dynamic_form.end_date && current_time > Time.parse(dynamic_form.end_date)
        render_message(dynamic_form.text_after_end_date)
      end
    end

    def render_message(html_content)
      DIV(dangerously_set_inner_HTML: { __html: html_content })
    end

    def dynamic_form
      return @dynamic_form if @dynamic_form
      @promise ||= Dynamic::Form.where(schema_id: request.params[:schema_id]).includes({ forbidden?: true }).find(request.params[:form_id]) do |dynamic_form|
        @dynamic_form = dynamic_form
        mutate
      end
      return @dynamic_form
    end

    def resize_iframe
      ::Element['html'].css('overflow-y', 'hidden')
      post_message({ iframe_height: height })
      Window.on(:resize) do
        $resize_timer&.abort
        $resize_timer = $window.after!(0.1) do
          post_message({ iframe_height: height })
        end
        $resize_timer.start
      end
      previous_height = nil
      every(0.2) do
        if height != previous_height
          post_message({ iframe_height: height })
        end
      end
    end

    def post_message(message)
      `top.postMessage(#{{iframeName: iframe_name}.merge(message).to_n}, '*')`
    end

    def iframe_name
      `window.name`
    end

    def dismiss_loading_message
      post_message({ iframeFormLoaded: 'loaded' })
    end

    def add_restore_to_request_params
      return if request.params[:options] && request.params[:options][:restore] == 'true'
      options = request.params[:options] || {}
      options[:restore] = true
      App.history.replace(App.location.add_params(options: options))
    end

    def height
      `document.documentElement.getBoundingClientRect().height`
    end

    def in_iframe?
      `top != window`
    end

    def auto_submit(form)
      form.submit.then do
        unless form.submission.errors.any?
          form.go_to_next_page
        end
      end
    end

    def execute_on_load_script
      return unless s = dynamic_form&.on_load_script
      Window.after(0) do # prevent full crash if there is an error in script
        JS.call(:eval, s)
      end
    end

    def change_window_title
      $window.document.title = window_title
    end

    def window_title
      return unless dynamic_form
      dynamic_form.human_name
    end

    class Message < HyperComponent

      collect_other_params_as :other_params

      before_mount do
        observe form if form
      end

      before_update do
        observe form if form
      end

      def form
        ::Form.current
      end

      render do
        next unless show?
        DIV(class: "alert alert-#{status_code == 200 ? 'success' : 'danger'}") do
          I18n.t("crm.forms.status_code.#{status_code}")
        end
      end

      def show?
        form&.data_loaded? && !form.enabled? && status_code
      end

      def status_code
        submission.status_code
      end

      def submission
        # keep previous submission until next submission has a status_code
        # because submission can have been reset but we wrant display a message
        @submission = nil if @submission && form.submission.status_code && @submission.status_code != form.submission.status_code
        @submission ||= form.submission
      end

      def timestamp
        other_params[:timestamp] || Time.now.to_f
      end

    end


  end

end
