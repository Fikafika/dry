class Settings
  class Schema
    class Appearance < ::Settings::Schema::Base

      render { content }

      def content
        update_recents
        layout(2) do
          parent_page(col: "col-sm-6 d-flex", active: 'appearance')
          appearance_page
        end
      end

      def current_model
        ::User.current.communities.detect{|c| c.name.to_s.downcase ==  request.params[:schema_id].to_s.downcase}
      end

      def current_item
        return self.class.item
      end

      def self.item
        {
          id: 'appearance',
          icon: I18n.t('icons.settings.appearance'),
          title: I18n.t('settings.appearance'),
        }
      end

      def appearance_page
        ::Stackable::LargePage() do
          if current_model&.loaded? && current_model.association(:theme).loaded?
            EditPanel(record: current_model, path: "#{index_location}/:id")
          end
        end
      end

      class EditPanel < ::Settings::Schema::EditPanel

        render { content }

        def header
          ::Stackable::Toolbar() do
            ::Stackable::PageHeader(title: I18n.t('settings.appearance'), back: back_location)
          end
        end

        def back_location
          request.location.pathname.gsub('/appearance', '')
        end

        def form
          Form(record: record) do
            Form::Element::Association::BelongsTo(
              attribute_name: 'theme_id',
            )
            children_list
          end.on(:success) do
            ::Dynamic::Theme.update_cache
            ::User.current(true) do
              community.update_appearance
              record.theme = theme
              mutate
            end
          end
        end

        def theme
          community&.theme
        end

        def community
          ::User.current.communities&.detect{|c| c.name.to_s.downcase ==  request.params[:schema_id].to_s.downcase}
        end

        def footer
          form_footer
        end

        def children_list
          DIV(class: 'row') do
            DIV(class: 'list-group flex-grow-1 overflow-auto') do
              if theme
                Stackable::PanelLink(item: {
                  id: 'edit-theme',
                  path: App.location.pathname.gsub("/appearance", "/themes/#{theme.name}/edit"),
                  icon: 'paint-brush',
                  title: I18n.t("shared.edit") + " " + theme.human_name,
                })
              end
              Stackable::PanelLink(item: {
                id: 'new-theme',
                path: App.location.pathname.gsub("/appearance", "/themes/new?community_appearance=1&human_name=#{community.name}"),
                icon: 'plus',
                title: I18n.t("shared.new") + " " + ::Dynamic::Theme.model_name.human.downcase,
              })
            end
          end
        end

      end

    end
  end

end

