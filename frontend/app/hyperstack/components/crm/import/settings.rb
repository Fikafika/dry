class Crm
  class Import
    class Settings < Base
      include ::Crm::CrmLayout

      render do
        content if schema.constants_loaded?
      end

      def content
        layout_with_toolbar(class: "overflow-auto vh-100-with-offset") do
          DIV(class: 'container-fluid pb-5') do
            if step > 0
              Crm::Import::StepProgress(current_step: step).on(:go_to_step) do |step|
                go_to_step(step)
              end
            end
            render_current_step
          end
        end
      end

      def render_current_step
        current_step_class = step_subclass
        if current_step_class
          component = current_step_class.create_element(schema: schema)
          component.render.on(:go_to_url) do |url|
            App.history.push(url)
          end.on(:next) do
            go_to_next_step
          end
        end
      end

      def global_toolbar_title
        if step && step > 0
          back_button
        else
          DIV(class: 'col-4') do
            SPAN(class: 'toolbar-title m-0 text-truncate btn-transparent-primary') do
              Dynamic::Import::Setting.model_name.human
            end
          end
        end
      end

      def global_toolbar_menu_items
        if step.nil? || step == 0
          DIV(class: 'col d-flex text-right') do
            GroupDrop() do
              new_button(variant: 'primary')
            end
          end
        end
      end

      def new_button(variant: 'light-yiq')
        Toolbar::Button(target: new_url, text: I18n.t('shared.new'), text_break: '', icon: 'plus', is_flex: true, variant: variant)
      end

      def step_subclass
        case step
        when 0
          Crm::Import::Step::RenderImports
        when 1
          Crm::Import::Step::SelectFile
        when 2
          Crm::Import::Step::Encoding
        when 3
          Crm::Import::Step::Transform
        when 4
          Crm::Import::Step::MapColumns
        when 5
          Crm::Import::Step::Deduplication
        when 6
          Crm::Import::Step::LaunchImport
        end
      end

      def step
        return 0 if request.params[:action] == 'index'
        (::App.location.query[:step] || 1).to_i
      end

      def go_to_next_step
        App.history.push(App.location.add_params(step: step + 1))
      end

      def go_to_step(n)
        App.history.push(App.location.add_params(step: n))
      end

    end
  end
end
