# backtick_javascript: true
require 'components/wait_for_completed_jobs'

class Crm
  class Sheet < Base

    collect_other_params_as :other_params

    fires :change

    render do
      ErrorBoundary do
        content
      end
    end

    class ErrorBoundary < ::ErrorBoundary

      def debug_message
        CloseButton(side: 'r') do
        end
        DIV(class: 'container-fluid') do
          DIV(class: 'row') do
            DIV(class: 'col') do
              DebugMessage(error: @error)
            end
          end
        end
      end

    end

    def content
      return unless ['new', 'show', 'edit', 'versions'].include?(action)
      DIV(class: 'crm-sheet record-mailto h-100', "data-recordclass": klass_name, "data-recordid": request.params[:id] || "") do
        content_component(request) || Layout(key: layout_key, dynamic_layout: dynamic_layout, request: request, side: side, on_change: Proc.new{|data| change!(data) })
      end
    end

    def request
      other_params[:path] ? ::Router::Resources::Request.new(other_params[:path]) : super
    end

    def action
      if other_params[:action]
        other_params[:action]
      else
        request.params[:action]
      end
    end

    def klass_name
      if other_params[:klass_name]
        other_params[:klass_name]
      else
        schema.klasses&.detect{|k| k.route_key == request.params[:klass]}&.const_absolute_name
      end
    end

    def schema
      observe @schema = Dynamic::Schema.load(schema_name)
    end

    def dynamic_layout
      observe Dynamic::Layout.load(schema_name, action, purpose, klass_name)
    end

    def schema_name
      if other_params[:schema_name]
        other_params[:schema_name]
      else
        request.params[:schema].classify_permalink
      end
    end

    def purpose
      other_params[:purpose]
    end

    def content_component(request)
      # TODO how to generalize using routes ?
      if request.location.pathname =~ /\/charts\//
        Chart::Settings(path: App.location.query[panel_param], layout_id: request.params[:l], side: side)
      elsif request.location.pathname =~ /\/versions$/
        Crm::Sheet::Versions(path: App.location.query[panel_param], side: side)
      else
        nil
      end
    end

    def layout_key
      @layout_key ||= "layout-#{generate_key}"
    end

    def generate_key
      @@generation ||= 0
      @@generation += 1
    end

    after_render do
      init_events
    end

    def init_events
      self.jq_node.off('reload.crm.sheet').on('reload.crm.sheet') do |e|
        reload
      end
      self.jq_node.off('close.crm.sheet').on('close.crm.sheet') do |e|
        close
      end
      self.jq_node.off('reload_after_create.crm.sheet').on('reload_after_create.crm.sheet') do |e|
        reload_after_create
      end
      self.jq_node.off('reload_after_update.crm.sheet').on('reload_after_update.crm.sheet') do |e|
        reload_after_update
      end
      self.jq_node.off('reload_after_destroy.crm.sheet').on('reload_after_destroy.crm.sheet') do |e|
        reload_after_destroy
      end
    end

    def reload
      mutate @layout_key = nil
    end

    def close
      return unless panel_param
      App.history.push(App.location.remove_param(panel_param))
    end

    def reload_after_create
      reload_opposite_sheet
      reload_index
      after(0.2) do # why ?
        close
      end
    end

    def reload_opposite_sheet
      opposite_sheet.trigger(:reload)
    end

    def reload_index
      ::Element['.crm-index'].trigger(:reload)
    end

    def reload_after_update
      reload_opposite_sheet
      reload_index
    end

    def opposite_sheet
      if side
        opposite_panel_id = side == 'left' ? 'right-panel' : 'left-panel'
        return ::Element["##{opposite_panel_id} .crm-sheet"]
      else
        return ::Element[""] # no element
      end
    end

    def reload_after_destroy
      reload_after_create
    end

    class FormParamsConverter < ::Layout::ParamsConverter
      include ::UrlHelper
      include WaitForCompletedJobs

      converter_for 'Form'

      def apply(params, options = {})
        result = super

        if params[:form_id]
          # for associated records overide dynamic_form_id
          result[:dynamic_form_id] = params[:form_id]
        end

        result[:schema_id] = params[:schema]

        on_change = options.dig(:layout_params, :on_change)

        result[:on_success] = Proc.new do |response, form|
          next unless form
          if form.mode == 'edit_in_place'
            form.jq_node.closest('.crm-sheet').trigger(:reload_after_update)
          else
            form.reset
          end
        end

        if params[:action] != 'new'
          result[:source_record_type] = dynamic_klass(params[:schema], params[:klass])&.name
          result[:source_record_id] =  params[:id]
          result[:on_finish] = on_change if on_change
        else
          if params[:source_record_id]
            result[:source_record_type] = params[:source_record_type]
            result[:source_record_id] =  params[:source_record_id]
          end
          if params[:target_record_id]
            result[:target_record_type] = params[:target_record_type]
            result[:target_record_id] =  params[:target_record_id]
          end

          compute_initial_params = dynamic_klass(params[:schema], params[:klass]).try(:compute_initial_form_params, params)
          params[:params] = compute_initial_params if compute_initial_params

          result[:on_finish] = Proc.new do |response, form|
            if ::Element[".crm-sheet"].length == 2 # two opened panels
              form.jq_node.closest('.crm-sheet').trigger(:reload_after_create)
            else
              on_change.call(response) if on_change
              App.history.push(redirect_url(params, response))
            end
          end
        end

        result[:params] = params[:params] if params[:params]
        result[:additional_submit_options] = wait_for_completed_jobs_options

        return result
      end

      def redirect_url(params, response = {})

        if params[:target_record_id]
          record_id = params[:target_record_id]
          record_type = params[:target_record_type]
        end

        if record_id.nil? && params[:source_record_id]
          record_id = params[:source_record_id]
          record_type = params[:source_record_type]
        end

        if record_id.nil?
          h = response[:records]&.select{|e| e['type']&.safe_constantize&.model_name&.route_key == params[:klass] && e['id'].present? }&.sort_by{|e| e[:id]}&.last
          record_id = h.try(:[], :id)
          record_type = h.try(:[], :type)
        end

        path = url_for(action: 'edit', id: record_id, klass: record_type.safe_constantize)

        panel_param = 'rp' # TODO

        if App.location.query[panel_param]
          result = App.location.add_params(panel_param => path)
        else
          result = path
        end

        return result
      end

    end

    class NewItemButton < ::Toolbar::Dropdown

      render { content }

      def content
        if children.length <= 1
          Link(child_target,  btn_params) do
            if image.present? && !@image_error
              IMG(image_params)
            elsif icon.present?
              I(icon_params)
            end
            SPAN(text_params) { text } if text.present?
          end
        else
          super
        end
      end

      def btn_params # redefined in order to manage 1 item
        return super unless children.length == 1
        return @btn_params if @btn_params
        result = other_params[:btn_params] || {}
        class_name = result.delete(:class)
        result[:class_name] = "btn #{class_name}"
        if children.length == 0
          result[:class_name] + "#{result[:class_name]} disabled"
        end
        side = children.first.props['data-open-panel'] if children.first if children.first&.respond_to?(:props)
        result[ 'data-open-panel'] = side if side
        return @btn_params = result
      end

      def child_target
        children.first&.respond_to?(:props) ? children.first.props['target'] : '#'
      end

      class ParamsConverter < ::Layout::ParamsConverter
        converter_for 'Crm::Sheet::NewItemButton'

        def apply(params, options = {})
          result = {
            icon: 'plus',
            text: options.dig('translations', I18n.locale, 'text') || I18n.t('shared.new'),
            btn_params: {
              :class => 'btn-transparent-light-yiq'
            }
          }
          return result
        end

      end

      module DropdownItem

        class ParamsConverter < ::Layout::ParamsConverter
          include UrlHelper
          converter_for 'Toolbar::Dropdown::Item'

          def apply(params, options = {})
            klass = options[:klass_name].safe_constantize
            `console.error(#{"DropdownItem: #{options[:klass_name]}"})` unless klass

            target = url_for(klass: klass, id: nil, action: 'new', mode: params[:mode])

            request = options[:layout_params][:request]

            target_record_type = dynamic_klass(request.params[:schema], request.params[:klass])&.name
            target_record_id = request.params[:id]

            target += "?form_id=#{options[:form_id]}&target_record_id=#{target_record_id}&target_record_type=#{target_record_type}"

            result = {
              text: options.dig('translations', I18n.locale, 'text'),
              target: target,
              'data-open-panel': 'opposite',
            }

            return result
          end

        end

      end

    end

  end
end
