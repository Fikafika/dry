require 'components/crm'

class Crm
  class Kanban
    module Setting
      class Form < HyperComponent
        param :schema
        param :klass
        param :dynamic_layout, default: nil
        param :column_settings, default: nil
        param :mode, default: nil
        param :layout_id, default: nil

        collect_other_params_as :other_params

        fires :save
        fires :change

        DEFAULT_COLUMN_SETTINGS = [{ value: nil, column_id: nil, position: 0 }]

        @@input_form_elements = [
          {
            key: 'column_attribute',
            mandatory: true,
            type: 'name',
          },
          {
            key: 'sprint_param',
            mandatory: false,
            type: 'association',
          }
        ]

        before_mount do
          @form_data ||= {}
          fill_up_form_data
        end

        def fill_up_form_data
          return unless element
          @@input_form_elements.each do |attribute|
            @form_data[attribute[:key]] = element.component_params[attribute[:key]]
          end
          change!(@form_data[:column_attribute])
        end

        after_mount do
          if other_params[:form_ref]
            other_params[:form_ref][:current] = self
          end
        end

        render do
          FORM(class: 'container p-2') do
            @@input_form_elements.each do |attribute|
              DIV(class: 'form-group') do
                LABEL { I18n.t("crm.kanban.setting.#{attribute[:key]}") }
                SELECT(class: 'form-control', required: attribute[:mandatory], value: @form_data[attribute[:key]]) do
                  OPTION(value: nil) do
                    I18n.t('shared.select')
                  end
                  if attribute['type'] == 'association'
                    klass.reflect_on_all_associations.reject(&:collection?).map(&:name).each do |association|
                      OPTION(value: association) do
                        klass.human_attribute_name(association)
                      end
                    end
                  else
                    klass.attribute_names.each do |column_name|
                      if klass.attributes[column_name][:type] == 'Enum'
                        OPTION(value: column_name) do
                          klass.human_attribute_name(column_name)
                        end
                      elsif klass.attributes[column_name][:type] == 'Uuid'
                        association_name = column_name.sub(/_id$/, '')
                        next unless klass.reflect_on_association(association_name) && !klass.reflect_on_association(association_name).collection?
                        OPTION(value: association_name) do
                          klass.human_attribute_name(association_name)
                        end
                      end
                    end
                  end
                end.on('change') do |e|
                  @form_data[attribute['key']] = e.target.value
                  change!(@form_data[attribute['key']].present?)
                  mutate
                end
              end
            end
            children.render
          end.on('submit') do |e|
            return unless @form_data[:column_attribute].present?
            e.prevent_default
            save_setting
          end
        end

        def element
          return nil unless dynamic_layout&.loaded?
          return dynamic_layout.elements.detect{ |e| e.component == 'Crm::Kanban' }
        end

        def save_setting
          case mode
          when :new, nil
            schema.layouts.create(
              id: layout_id,
              human_name_fr: 'Kanban',
              human_name_en: 'Kanban',
              actions: [:index],
              mode: 'kanban', # TODO remove
              klass_name: klass,
              elements_attributes: [
                {
                  component: 'Crm::Kanban',
                  component_params_converter_type: 'Crm::Index::ParamsConverter',
                  component_params: {
                    column_attribute: @form_data['column_attribute'],
                    sprint_param: @form_data['sprint_param'],
                    column_settings: DEFAULT_COLUMN_SETTINGS,
                  },
                }
              ]
            ) do |response|
              Dynamic::Layout.update_cache([:first, :all, :find])
              save!
            end
          when :edit
            column_settings = element.component_params['column_attribute'] != @form_data['column_attribute'] ? DEFAULT_COLUMN_SETTINGS : element.component_params[:column_settings]
            dynamic_layout.update(
              elements_attributes: [
                {
                  id: element.id,
                  component_params: {
                    column_attribute: @form_data['column_attribute'],
                    sprint_param: @form_data['sprint_param'],
                    column_settings: column_settings,
                  },
                }
              ]
            ).then do |response|
              Dynamic::Layout.update_cache([:first, :all, :find])
              save!
            end
          end
        end
      end
    end
  end
end
