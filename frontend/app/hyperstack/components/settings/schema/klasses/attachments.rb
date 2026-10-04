class Settings

  class Schema

    class Attachments < Klasses::Base

      render { content }

      def klass
        ::Dynamic::Schema::Attachment::Base
      end

      def new_record
        klass.new({
          schema_id: match.params['schema_id'],
          owner_klass_id: match.params['klass_id'],
          type: 'HasOne',
        })
      end

      def schema_klasses
        observe Dynamic::Schema::Klass.where({
          schema_id: match.params['schema_id'],
        }).all
      end

      def edit_panel
        EditPanel(record: current_model, schema_klasses: schema_klasses, path: "#{index_location}/:id", schema: schema)
      end

      class EditPanel < ::Settings::Schema::EditPanel

        param :schema_klasses

        render { content }

        def form
          Form(record: record) do
            Form::Element::Attribute::TranslatableString(
              attribute_name: 'human_name',
              errors_from: 'name',
              help: record.new_record? ? '' : I18n.t('activerecord.defaults.attributes.variable_name_text', variable_name: record.name),
              auto_focus: true,
            )
            Form::Element::Attribute::Enum(
              attribute_name: 'type',
              disabled: record.persisted?,
            ) do
              ::Dynamic::Schema::Attachment::Base.subclasses.each do |klass|
                OPTION(value: klass.name.demodulize) do
                  klass.model_name.human
                end
              end
            end
            Extensions(
              attribute_name: 'extensions',
            )
            Form::Element::Attribute::Float(
              attribute_name: 'size_limit',
              step: 1,
              help: I18n.t('settings.attachments.megabytes'),
            )
            if schema.has_feature_enabled?('Dynamic::Formula::Feature')
              Formula(
                attribute_name: 'formula',
                klass_id_attr: 'owner_klass_id',
                schema: schema,
                height: '300px',
              )
            end
            comment
            children_list
          end.on(:success) do
            App.history.push(record_location)
          end
        end

        def footer
          form_footer
        end

        def children_items
          children_klasses = []
          children_klasses << ::Dynamic::Schema::Attachment::Variant
          children_klasses.map do |a|
            {
              id: self.class.parent.resources_name(a),
              icon: a.icon,
              title: a.model_name.human(count: 2),
            }
          end
        end

        class Extensions < Form::Element::Attribute::MultipleEnum

          def default_editor
            'tom_select'
          end

          def possible_values
            (form&.submission&.read(path) || []).map{|v| {value: v, label: v}}
          end

          def selected_values
            possible_values
          end

          def tom_select_options
            super.merge({
              valueField: 'extension',
              labelField: 'extension',
              searchField: 'extension',
              onFocus: -> () {
                `this.load();`
              },
              load: ->(query, callback) {
                url = "#{ENV['APP_PATH_PREFIX']}/api/mime_types.json"
                HttpWithCrossDomain.get(url) do |response|
                  if response.ok?
                    `callback(#{`#{response.xhr}.responseJSON`})`
                  else
                    `callback()`
                  end
                end
              },
              onItemAdd: ->() {
                `this.setTextboxValue('');`
                `this.refreshOptions();`
              },
              render: {
                option: ->(item, escape) {
                  "<div>.#{`item.extension`}</div>"
                },
                item: ->(data, escape) {
                  v = `escape(data.extension)`
                  %Q[<div title=".#{v}"class="create">.#{v}</div>]
                },
                loading: ->(data, escape) {
                  '<div class="ml-2 fa fa-spinner fa-pulse"></div>'
                },
                no_results: ->(data, escape) {
                  %Q[<div class="no-results">#{I18n.t('shared.none') }</div>]
                },
              },
            })
          end
        end

      end

      class CollectionPage < ::Settings::Schema::CollectionPage
        include ::Settings::Schema::Klasses::Base::ItemIconAssigner

        def model_to_item(model)
          item = super(model)
          return item unless item
          attach_icons_to_item(model, item)
        end
      end

    end

  end

end
