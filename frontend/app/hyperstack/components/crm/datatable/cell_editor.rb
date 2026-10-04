require 'components/wait_for_completed_jobs'

class Crm
  class Datatable

    class CellEditor < HyperComponent
      include Crm::Routes::Helpers
      include Crm::Datatable::RecordFromCell
      include WaitForCompletedJobs
      include OutsideOfRendering

      param :klass, default: nil
      param :cell, default: nil

      collect_other_params_as :others

      fires :close
      fires :success
      fires :error

      after_mount do
        add_close_listener_to_body
      end

      def add_close_listener_to_body
        ::Element['body'].on('mousedown.cellEditor') do |event|
          @mousedown_inside_cell = self.jq_node.has(::Element[event.target]).length > 0
        end
        ::Element['body'].on('click.cellEditor') do |event|
          mousedown_inside_cell = @mousedown_inside_cell
          @mousedown_inside_cell = false
          unless mousedown_inside_cell || self.unmounted? || self.jq_node.has(::Element[event.target]).length > 0
            close!
          end
        end
      end

      before_unmount do
        remove_close_listener_from_body
      end

      def remove_close_listener_from_body
        ::Element['body'].off("click.cellEditor")
        ::Element['body'].off("mousedown.cellEditor")
      end

      render do
        DIV(class: 'cell-editor') do
          if prevent_edit?
            close!
          elsif create_new_record?
            create_new_record
          else
            backdrop
            if record.loaded?
              Form(
                record: record,
                class: 'position-absolute bg-body',
                style: position,
                additional_submit_options: additional_submit_options,
              ) do
                autocomplete_variable_elements
                ::Form::Element.klass_from_method_name(record.class, record_method_name).create_element(
                  attribute_name: record_method_name,
                  mode: :edit_cell,
                  input_class: 'form-control-sm',
                  possible_values: possible_values,
                ).render
              end.on(:success) do
                ::Dynamic::Form.clear_cache_with_serialized_records
                success!(record)
                redraw_cell do
                  close!
                end
              end.on(:error) do
                error!(record)
                close!
              end.on(:cancel) do
                close!
              end.on(:click) do |event|
                event.stop_propagation
              end
            end
          end
        end
      end

      def autocomplete_variable_elements
        autocomplete_variables.each do |variable|
          element_klass = ::Form::Element.klass_from_method_name(record.class, variable)
          next unless element_klass
          element_klass.create_element(
            key: variable,
            attribute_name: variable,
            editor: 'hidden',
            show_label: false,
          ).render
        end
      end

      def autocomplete_variables
        filters = association.try(:default_elasticsearch_filters)
        return [] unless filters
        ::Form::Element::Base.extract_variables(filters).uniq.reject do |variable|
          variable.include?('.') || variable == record_method_name
        end
      end

      def prevent_edit?
        virtual? || (association && association.class.name == 'HyperResource::Reflection::BelongsToReflection' && association.options[:dependent] == :destroy && record&.id)
      end

      def virtual?
        klass&.indexable_virtual_attributes&.[](record_method_name)
      end

      def create_new_record?
        return (association && association.options[:dependent] == :destroy) || !record
      end

      def association
        record_klass.reflect_on_association(record_method_name)
      end

      def record_klass
        record_klass_name.constantize
      end

      def record_klass_name
        col.klass.name
      end

      def record_method_name
        col.method_name
      end

      def col
        klass.datatable_column_by_name[cell.table.column(parent_td(cell)).name]
      end

      def record
        return unless cell
        id = record_id(cell)
        return unless id
        observe @record ||= record_klass.includes(record_includes).find_without_cache(id)
      end

      def record_includes
        result = {}
        if association
          result[record_method_name] = 1
        elsif record_klass&.reflect_on_attachment(record_method_name)
          result[record_method_name] = Dynamic::Base.active_storage_includes
        end
        autocomplete_variables.each do |variable|
          result[variable] = 1 if record_klass.reflect_on_association(variable)
        end
        return result
      end

      def create_new_record
        outside_of_rendering do
          if association
            if association.klass
              col.form_id_for(:new) do |form_id|
                rp  = new_url(association.klass)
                rp = add_param_to_url(rp, 'form_id', form_id)
                rp = add_param_to_url(rp, 'target_record_id', record.id)
                rp = add_param_to_url(rp, 'target_record_type', record_klass_name)
                open_right_panel(rp)
              end
            end
          else
            rp = new_url(record_klass_name.safe_constantize)
            open_right_panel(rp)
          end
        end
      end

      def open_right_panel(url)
        App.history.push(App.location.add_params('rp' => url))
      end

      def backdrop
        DIV(class: 'modal-backdrop w-100 h-100 show') do
        end.on(:click) do |event|
          event.stop_propagation
          close!
        end
      end

      def possible_values
        return [] unless record
        return record.class.attributes.dig(record_method_name, :possible_values, I18n.locale)
      end

      def position
        e = cell.element

        top = e.offset.top
        left = e.offset.left

        width = e.outer_width
        if width < min_with
          width = min_with
        end
        {
          zIndex: 10000,
          left: left,
          top: top,
          width: width.to_s + 'px',
        }
      end

      def min_with
        150
      end

      def additional_submit_options
        r = wait_for_completed_jobs_options
        r = r.merge(versioning) if layout_id
        return r
      end

      def versioning
        {
          versioning: {
            source_type: 'Dynamic::Layout',
            source_id: layout_id,
          },
        }
      end

      def layout_id
        if request.params[:_] && request.params[:_] =~ /[\(,]l\:'([^']+)'/
          return $1
        end
        return request.params[:l]
      end

      def redraw_cell
        if block_given?
          datatable.draw_callbacks << Proc.new do
            yield
          end
        end
        cell.draw('page')
      end

      def datatable
        ::Element.find(cell.table.node.to_n).data('get_component').call
      end

    end

  end
end

