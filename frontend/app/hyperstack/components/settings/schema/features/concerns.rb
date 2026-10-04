class Settings

  class Schema

    class Features

      class Concerns < Base
        render{ content }

        def klass
          ::Dynamic::Schema::Concern
        end

        def scope_for_all
          super.merge(feature_id: match.params[:feature_id])
        end

        def self.includes_for_all
          { include: { translations: 1, options: 1, feature: 1, klass: { include: { translations: 1 } } } }
        end

        def new_record
          Dynamic::Schema::Concern.new({
            feature: schema_feature, # TODO: should be assigned by association's inverse of
            schema_id: match.params['schema_id'],
          })
        end

        def parent_parent_page(params = {})
          CollectionPage(
            klass: Dynamic::Schema::Feature,
            resource_id_key: :feature_id,
            path_prefix: path_prefix,
            location: features_location,
            location_suffix: parent_parent_location_suffix,
            scope_for_all: {schema_id: match.params[:schema_id]},
            includes_for_all: { include: { translations: 1 } },
            schema: schema,
          )
        end

        def schema_klasses
          observe Dynamic::Schema::Klass.order(human_name: :asc).where({
            schema_id: match.params['schema_id'],
          }).limit(200).all # TODO assume there is less than 200 classes
        end

        class CollectionPage < ::Settings::CollectionPage
          def model_to_item(model)
            return nil unless model
            return {
              id: model.id + location_suffix,
              icon: model.class.icon,
              title: model.try(:human_name),
              subtitle: model.klass.try(:human_name)
            }
          end

        end

        def edit_panel
          EditPanel(record: current_model, schema_klasses: schema_klasses, path: "#{index_location}/:id", schema: schema)
        end

        class EditPanel < ::Settings::Schema::EditPanel

          param :schema_klasses

          render { content }

          def form
            observe schema_klasses

            Form(record: record) do
              if record.new_record?
                Form::Element::Attribute::Enum(
                  attribute_name: 'concern_template',
                ) do
                  OPTION(value: '')
                  record.feature.concern_templates&.each do |c|
                    OPTION(value: c.id) do
                      c.human_name
                    end
                  end
                end.on(:change) do |value, form|
                  template = record.feature.concern_templates.detect{|c| c.id == value }
                  if template
                    form.submission.write_from_user(['concern', 'name'], template.name)
                    form.submission.write_from_user(['concern', 'human_name_fr'], template.human_name_fr)
                    form.submission.write_from_user(['concern', 'human_name_en'], template.human_name_en)
                    options = template.options.map do |opt|
                      {
                        human_name_fr: opt.human_name_fr,
                        human_name_en: opt.human_name_en,
                        human_name: opt.human_name,
                        name: opt.name,
                        type: opt.type,
                        coder_type: opt.coder_type,
                        global: opt.global,
                        value: opt.value,
                      }
                    end
                    form.submission.write_association(['concern', 'options'], options)
                  else
                    form.submission.write_from_user(['concern', 'name'], nil)
                    form.submission.write_from_user(['concern', 'human_name_fr'], nil)
                    form.submission.write_from_user(['concern', 'human_name_en'], nil)
                    form.submission.write_association(['concern', 'options'], [])
                  end
                  mutate
                end
              end
              Form::Element::Attribute::Enum(
                attribute_name: 'klass_id',
              ) do
                OPTION(value: '')
                schema_klasses&.each do |klass|
                  OPTION(value: klass.id) do
                    klass.human_name
                  end
                end
              end.on(:change) do
                mutate
              end

              comment
              Settings::Schema::Features::EditPanel.options(schema)
            end.on(:success) do
              others[:schema].stale!
              App.history.push(record_location)
            end

          end

          def footer
            form_footer
          end

        end
      end

    end

  end

end
