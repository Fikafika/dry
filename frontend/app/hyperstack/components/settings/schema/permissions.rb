class Settings
  class Schema
    class Permissions < ::Settings::Schema::Base

      render { content }

      def content
        update_recents
        observe rules if resource_name
        layout(layout_page_count) do
          if request.params[:action] == 'index'
            parent_parent_page
            parent_page(active: 'rules')
            list_page
          else
            parent_page(active: 'rules')
            list_page
            permissions_page
          end
        end
      end

      def layout_page_count
        resource_name ? 3 : 2
      end

      def editable?
        false
      end

      def self.resource_id_key
        :name
      end

      def self.resources_name(klass = nil)
        'rules'
      end

      def resource_name
        request.params[:name]
      end

      def self.child_klasses
        {
          'exports' => Dynamic::Export::Setting,
          'imports' => Dynamic::Import::Setting,
          'templates' => Dynamic::DocGen::Template,
          'mail_rules' => Dynamic::MailHosting::Rule,
          'copy_mappings' => Dynamic::Copy::Mapping,
          'copies' => Dynamic::Copy::Setting,
        }
      end

      def self.children_items
        child_klasses.map do |k, v|
          {
            id: k,
            icon: v.icon,
            title: v.model_name.human
          }
        end
      end

      def permissions_page
        Stackable::LargePage() do
          Stackable::Toolbar() do
            Stackable::PageHeader(title: active_klass.model_name.human, back: location)
          end
          ::Permission::Manager(
            rules: rules,
            params_for_new_record: params_for_new_record,
            reload: @reload
          )
        end
      end

      def active_klass
        self.class.child_klasses[resource_name]
      end

      def klass_name
        active_klass.name
      end

      def rules
        result = ::UneekPermission::Rule.where(klass_name: klass_name, schema_name: schema.name).all do
          @reload = true
        end
        result.sort_by! { |a, b| a && b ? a <=> b : a.nil? ? -1 : 1 } if result.try(:records)
        return result
      end

      def params_for_new_record
        return {
          klass_name: klass_name,
          attr: nil,
          schema_name: schema.name
        }.merge!(params_for_instance)
      end

      def params_for_instance
        result = {}

        case resource_name
        when 'mail_rules'
          f_id = schema.features.detect {|f| f.name == 'Dynamic::MailHosting::Feature'}
          result = {instance_type: 'Dynamic::Schema::Feature', klass_name: 'Dynamic::Schema::Feature', instance_id: f_id} if f_id
        end

        return result
      end

        def list_page
          CollectionPage(
            klass: klass,
            resource_id_key: resource_id_key,
            path_prefix: path_prefix,
            location: index_location,
            scope_for_all: scope_for_all,
            includes_for_all: includes_for_all,
            editable: editable?,
            active: resource_name
          )
        end

      class CollectionPage < ::Settings::CollectionPage

        render { content }

        def list_title
          UneekPermission::Rule.model_name.human
        end

        def items
          self.class.parent.children_items
        end

        def content
          layout do
            Stackable::Toolbar() do
              Stackable::PageHeader(title: list_title, back: back_location) do
                action_menu
              end
            end
            Stackable::List({
              active: others[:active],
              items: items,
              location: location
            })
          end
        end

      end

    end
  end
end
