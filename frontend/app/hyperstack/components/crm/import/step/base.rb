# backtick_javascript: true

class Crm
  class Import
    module Step
      class Base < ::Crm::Import::Base

        param :schema, default: nil
        collect_other_params_as :others

        fires :go_to_url
        fires :next

        before_new_params do |next_props|
          @setting = nil
        end

        def setting
          if request.params[:action] == 'new'
            @setting ||= setting_scope.new(schema_id: request.params[:schema_id])
          else ['edit', 'show'].include?(request.params[:action])
            @setting ||= setting_scope.find(request.params[:import_setting_id]) { mutate }
          end
          return @setting
        end

        def setting_scope
          Dynamic::Import::Setting.where(schema_id: request.params[:schema_id], visible: true).includes(setting_includes)
        end

        def job(id)
          setting.jobs.detect{|job| job.id == id }
        end

        def source
          setting.sources.sort_by{|s| s.created_at}.first
        end

        def setting_includes
          {}
        end

        def csv_includes
          {
            include: {
              attachment: {
                include: {
                  signed_id: 1,
                  filename: 1,
                  blob: {
                    include: {
                      signed_id: 1,
                      filename: 1,
                    }
                  }
                }
              }
            }
          }
        end

        def footer
          @was_new_record = setting.new_record?
          DIV(class:"d-flex flex-row justify-content-end my-3") do
            cancel_button
            save_button
            save_and_next_button
          end
          setting_error_message
        end

        def cancel_button
          BUTTON(class:"btn bg-light border-0 rounded-0", type: 'button') do
            I18n.t('shared.cancel')
          end.on(:click) do |event|
            event.prevent_default
            process_cancel_button(event)
          end
        end

        def process_cancel_button(event)
          @setting = nil
          setting.reload do |response|
            mutate setting
          end
        end

        def save_button
          BUTTON(class:"btn btn-primary border-0 rounded-0 mx-2 #{'disabled' if @saving}", type: 'button') do
            SPAN do
              I18n.t('shared.save')
            end
            I(class: 'ml-2 fa fa-spinner fa-pulse') if @requesting_save
          end.on(:click) do |event|
            event.prevent_default
            process_save_button(event)
          end
        end

        def process_save_button(event)
          @saving = true
          mutate @requesting_save = true
          process_action_before_saving
          object_to_save.then do |response|
            @saving = false
            mutate @requesting_save = false
            if response[:success]
              process_action_on_success
              if @was_new_record
                go_to_url!(edit_url(setting.id))
              end
            end
            mutate setting
          end
        end

        def process_action_before_saving
        end

        def process_action_on_success
        end

        def object_to_save
          setting.save
        end

        def save_and_next_button
          BUTTON(class:"btn btn-primary border-0 rounded-0 #{'disabled' if @saving}", type: 'button') do
            SPAN do
              I18n.t('crm.import.settings.save_and_next')
            end
            I(class: 'ml-2 fa fa-spinner fa-pulse') if @requesting_save_and_next
          end.on(:click) do |event|
            event.prevent_default
            process_save_and_next_button(event)
          end
        end

        def process_save_and_next_button(event)
          @saving = true
          mutate @requesting_save_and_next = true
          process_action_before_saving
          object_to_save.then do |response|
            @saving = false
            mutate @requesting_save_and_next = false
            if response[:success]
              process_action_on_success
              if @was_new_record
                go_to_url!(edit_url(setting.id))
              else
                next!
              end
            end
            mutate setting
          end
        end

        def setting_error_message
          return unless setting&.errors&.any?
          DIV(class: "row mt-2 justify-content-end") do
            message = setting.errors['message']
            if message.is_a?(String)
              DIV class: 'alert alert-danger', role: 'alert' do
                message == 'error' ? I18n.t("shared.error") : message
              end
            else
              DIV class: 'alert alert-danger', role: 'alert' do
                setting.errors.each do |attr, errors|
                  errors.each do |error|
                    DIV() do
                      "#{setting.class.human_attribute_name(attr)} #{I18n.error(error, setting, attr)}"
                    end
                  end
                end
              end
            end
          end
        end

        def generate_dropdown_subclasses(classes)
          DIV(class: 'dropdown-menu') do
            classes.each do |klass|
              disabled = ""
              if !Crm::Import::Step::Item.from_type(klass.name.demodulize).has_parent_id? &&
                 @items.select { |t| t['type'] == klass.name && t.has_key?("_destroy") }.blank? &&
                 @items.map { |t| t['type'] }.include?(klass.name)
                disabled = "disabled bg-light"
              end
              A(class: "dropdown-item #{disabled}") do
                klass.model_name.human
              end.on(:click) do |event|
                event.prevent_default
                if Crm::Import::Step::Item.from_type(klass.name.demodulize).has_parent_id?
                  @items.push(klass.attributes_for_new_instance)
                else
                  if Crm::Import::Step::Item.from_type(klass.name.demodulize).should_be_first?
                    @items.unshift(klass.attributes_for_new_instance)
                  else
                    last_without_parent_id_position = @items.map { |t| !Crm::Import::Step::Item.from_type(t['type'].demodulize).has_parent_id? }.rindex(true)
                    position = last_without_parent_id_position.nil? ? 0 : last_without_parent_id_position + 1
                    @items.insert(position, klass.attributes_for_new_instance)
                  end
                end
                mutate
              end
            end
          end
        end

        def scroll_to_top_button
          BUTTON(
            class:"btn btn-secondary position-fixed",
            style: {
              width: "50px",
              bottom: "2rem",
              right: "2rem",
            },
            'data-toggle': "tooltip",
            title: I18n.t("shared.button_to_top")
          ) do
            I(class: "fa-solid fa-arrow-up")
          end.on(:click) do |event|
            scroll_to_top
          end
        end

        def scroll_to_top
          ::Element['.vh-100-with-offset'].scroll_top(0)
        end
      end
    end
  end
end

class Numeric
  Alpha26 = ("a".."z").to_a
  def to_s26
    return "" if self < 1
    s, q = "", self
    loop do
      q, r = (q - 1).divmod(26)
      s = s + Alpha26[r]
      break if q.zero?
    end
    s.reverse
  end
end
