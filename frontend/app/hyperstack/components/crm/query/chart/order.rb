class Crm
  module Query
    module Chart
      class Order < Form::Element::Base

        param :chart
        param :klass

        render { content }

        def render_input
          observe form.submission
          layout_input do
            v = normalize_value(form.submission.read(path))
            if v.nil?
              I18n.t('shared.non_f')
            else
              DIV(class: 'row') do
                DIV(class: 'col') do
                  label_for_axis('x')
                  direction('x')
                end
                DIV(class: 'col') do
                  label_for_axis('y')
                  direction('y')
                end
              end
            end
          end
        end

        def normalize_value(v)
          return {'x' => nil, 'y' => nil} unless v.is_a?(Hash) && (v.key?('x') || v.key?('y'))
          {'x' => v['x'], 'y' => v['y']}
        end

        def label_for_axis(axis)
          LABEL do
            I18n.t("crm.query.params.chart.axis.#{axis}")
          end
        end

        def column_label(col)
          return unless col
          r = []
          klass = self.klass
          col.split('.').each do |c|
            next unless klass
            r << klass.human_attribute_name(c)
            if klass.reflect_on_association(c)
              klass = klass.reflect_on_association(c).klass
            end
          end
          return r.join(' < ')
        end

        def direction(axis)
          v = normalize_value(form.submission.read(path))
          SELECT(class: 'form-control', value: v[axis]) do
            OPTION(value: '') do
              nil
            end
            ['asc', 'desc'].each do |dir|
              OPTION(value: dir) do
                I18n.t("activerecord.values.dynamic/form/element/base.sorting_type.#{dir}")
              end
            end
          end.on(:change) do |event|
            v = normalize_value(form.submission.read(path))
            v[axis] = event.target.value.to_s
            change_value(v)
            mutate
          end
        end

        def displayed_label
          I18n.t('crm.query.params.chart.order')
        end

        def change_value(value)
          return unless form && !form.reseting?
          old_value = normalize_value(form.submission.read(path))
          new_value = normalize_value(value)
          if new_value != old_value
            form.enable
            form.submission.write_from_user(path, new_value)
            change_data(new_value)
            mutate
            change!(new_value, form, self)
            form.change
          end
        end
      end
    end
  end
end
