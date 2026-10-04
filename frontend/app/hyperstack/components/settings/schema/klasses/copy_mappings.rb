class Settings
  class Schema
    class Klasses

      module CopyMappingsShared

        def self.direction_items(back_location)
          [
            {
              id: CopyMappingsOutgoing.resources_name,
              icon: 'arrow-right-from-bracket',
              title: I18n.t('settings.klasses.copy_mappings_outgoing'),
              path: "#{back_location}/#{CopyMappingsOutgoing.resources_name}",
            },
            {
              id: CopyMappingsIncoming.resources_name,
              icon: 'arrow-right-to-bracket',
              title: I18n.t('settings.klasses.copy_mappings_incoming'),
              path: "#{back_location}/#{CopyMappingsIncoming.resources_name}",
            },
          ]
        end

        def klass
          return nil unless schema&.constants_loaded?
          schema.const::R::Copy::Mapping
        end

        def models
          []
        end

        def edit_page
          ::Stackable::LargePage() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: edit_page_title, back: back_location_for_edit) do
                edit_action_menu
              end
            end
            DIV(class: 'p-3 overflow-auto h-100') do
              ::Crm::Copy::Mapping(
                klass_name: schema_klass_name,
                mode: mode,
                mapping_id: match.params[:mapping_id],
                is_new: match.params[:action] == 'new',
                back_location: back_location_for_edit,
              )
            end
          end
        end

        def edit_action_menu
          return if match.params[:action] == 'new' || match.params[:mapping_id].blank?
          DIV(class: 'dropdown') do
            BUTTON(class: 'btn btn-transparent-light-yiq shadow-none dropdown-toggle dropdown-toggle-ellipsis', type: 'button', 'data-toggle': 'dropdown') {}
            DIV(class: 'dropdown-menu dropdown-menu-right') do
              A(href: '#', class: 'dropdown-item text-capitalize-first-letter') do
                I(class: 'fas fa-trash mr-2')
                I18n.t('shared.delete')
              end.on(:click) do |event|
                event.prevent_default
                delete_mapping_from_header
              end
            end
          end
        end

        def delete_mapping_from_header
          return unless schema&.constants_loaded?
          mapping_class = schema.const::R::Copy::Mapping
          ::Modal.confirm(title: I18n.t('shared.delete')) do
            mapping = mapping_class.find(match.params[:mapping_id])
            mapping.destroy.then do |response|
              if response[:success]
                App.history.push(back_location_for_edit)
              end
            end
          end
        end

        def list_page
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: page_title, back: back_location)
            end
            ::Stackable::List(
              active: active_mapping_id,
              items: mapping_items,
              location: index_location,
            )
            ::Stackable::AddButton(href: new_mapping_url)
          end
        end

        def active_mapping_id
          match.params[:mapping_id] if match.params[:mapping_id].present? && match.params[:action] != 'new'
        end

        def mapping_items
          return [] unless schema&.constants_loaded?
          mapping_class = schema.const::R::Copy::Mapping
          key = mode == 'source' ? :source_klass_name : :target_klass_name
          (observe mapping_class.where(key => schema_klass_name).all).map do |m|
            {
              id: m.id,
              icon: 'right-left',
              title: m.name.presence || mapping_default_label(m),
            }
          end
        end

        def mapping_default_label(m)
          "#{klass_label(m.source_klass_name)} → #{klass_label(m.target_klass_name)}"
        end

        def klass_label(klass_name)
          k = schema.klasses.detect { |kl| kl.const_absolute_name == klass_name }
          k&.human_name || k&.name || '?'
        end

        def edit_page_title
          if match.params[:action] == 'new'
            I18n.t('crm.copy.mappings.new')
          else
            I18n.t('shared.edit')
          end
        end

        def new_mapping_url
          "#{back_location}/#{self.class.resources_name}/new"
        end

        def edit_mapping_url(id)
          "#{back_location}/#{self.class.resources_name}/#{id}/edit"
        end

        def back_location_for_edit
          "#{back_location}/#{self.class.resources_name}"
        end

        def mode
          self.class.mode
        end

        def parent_page(params = {})
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: I18n.t('settings.klasses.copy_mappings'), back: copy_mappings_back_location)
            end
            ::Stackable::List(
              active: self.class.resources_name,
              items: direction_items,
              location: copy_mappings_back_location,
            )
          end
        end

        def parent_parent_page(params = {})
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: schema_klass.human_name, back: parent_back_location)
            end
            ::Stackable::List(
              active: CopyMappings.resources_name,
              items: ::Settings::Schema::Klasses.children_items(schema, schema_klass),
              location: back_location,
            )
          end
        end

        def copy_mappings_back_location
          "#{back_location}/#{CopyMappings.resources_name}"
        end

        def direction_items
          CopyMappingsShared.direction_items(back_location)
        end

      end

      class CopyMappings < Base
        render { content }

        def self.feature
          'Dynamic::Copy::Feature'
        end

        def self.resources_name
          'correspondences'
        end

        def self.resource_id_key
          'direction'
        end

        def edit_page
          nil
        end

        def list_page
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: I18n.t('settings.klasses.copy_mappings'), back: back_location)
            end
            ::Stackable::List(
              active: nil,
              items: direction_items,
              location: back_location,
            )
          end
        end

        def direction_items
          CopyMappingsShared.direction_items(back_location)
        end
      end

      class CopyMappingsOutgoing < Base
        include CopyMappingsShared
        render { content }

        def self.feature
          'Dynamic::Copy::Feature'
        end

        def self.resources_name
          'copy_mappings_outgoing'
        end

        def self.resource_id_key
          'mapping_id'
        end

        def self.mode
          'source'
        end

        def page_title
          I18n.t('settings.klasses.copy_mappings_outgoing')
        end
      end

      class CopyMappingsIncoming < Base
        include CopyMappingsShared
        render { content }

        def self.feature
          'Dynamic::Copy::Feature'
        end

        def self.resources_name
          'copy_mappings_incoming'
        end

        def self.resource_id_key
          'mapping_id'
        end

        def self.mode
          'target'
        end

        def page_title
          I18n.t('settings.klasses.copy_mappings_incoming')
        end
      end

    end
  end
end
