require 'components/form/element/control/base'

class Form
  module Element
    module Control
      class AddButton < Base

        render { content }

        def render_input
          DIV(ref: _ref, class: 'row') do
            DIV(class: 'col text-right') do
              A(href: "#add", class: "btn btn-light") do
                text || I18n.t('shared.add')
              end.on(:click) do |event|
                event.prevent_default
                next if max_reached?
                values = form.submission.read_association(path) || []
                values << new_record_attrs
                form.submission.write_association(path, values)
                form.submission.write_association_values(path, values, false) unless in_editor
                form.mutate
                form.enable
              end
            end
          end
        end

        def render_readonly
          # don't render
        end

        def render_edit_in_place
          DIV(ref: _ref, class: 'row') do
            DIV(class: 'col text-right') do
              crm_sheet_new_button
            end
          end
        end

        private

        def max_reached?
          max ? count >= max : false
        end

        def count
          values = form.submission.read_association(path)
          return values ? values.select{|v| !v[:_destroy] }.length : 0
        end

        def max
          form.association_max && form.association_max[path]
        end

        def new_record_attrs
          r = attrs_for_new_record.dup
          r[:position] = form.submission.new_position(path) if orderable_association?
          r
        end

        def attrs_for_new_record
          other_params[:attrs_for_new_record] || {}
        end

        def init_submission_params
        end

        def orderable_association?
          !!target_klass&.attributes&.dig('position')
        end

        def target_klass
          (other_params[:target_klass] || (record && record.class.reflect_on_association(path.last)&.klass))
        end

        def crm_sheet_new_button
          if target_klass && request.params[:schema]
            observe forms = Dynamic::Form.with_action(:new).where(
              klass_name: target_klass.name,
              target_klass_name: record.class.name,
              schema_id: request.params[:schema],
              association_name: path.last,
            ).all
          else
            # TODO polymorphic
            # element should have a list of klass (see element/association/base#target_klass_url)
            forms = []
          end

          ::Crm::Sheet::NewItemButton(text: text || I18n.t('shared.new'), btn_params: { :class => 'btn-transparent-light-yiq' }) do
            forms.each do |f|
              target = "/crm/#{request.params[:schema]}/#{request.params[:mode]}/#{f.klass_name.safe_constantize&.model_name&.route_key}/new"
              target += "?form_id=#{f.id}&target_record_id=#{record.id}&target_record_type=#{record.class.name}"
              ::Toolbar::Dropdown::Item(
                text: f.human_name,
                target: target,
                'data-open-panel': 'opposite',
              )
            end
          end
        end

      end
    end
  end
end
