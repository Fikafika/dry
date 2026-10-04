module Dynamic
  module Kanban
    module Feature; extend Dynamic::Feature

      def self.feature_attributes
        {
          human_name_fr: 'Kanban',
          human_name_en: 'Kanban',
          mandatory: false,
          enabled: false
        }
      end

      def self.load(schema)
      end

      def self.after_enabled(feature)
        schema = feature.schema
        create_klasses(schema)
      end

      def self.create_klasses(schema)
        return if schema.klasses.detect{|k| k.name == 'Sprint' || k.name == 'Issue'}

        sprint_klass = schema.klasses.create!(
          name: 'Sprint',
          human_name_fr: 'Sprint',
          human_name_en: 'Sprint',
          update_menu_items: false,
          icon: 'running',
          attrs_attributes: [{
            name: 'name',
            human_name_fr: 'Nom',
            human_name_en: 'Name',
            type: 'String',
          },{
            name: 'start_at',
            human_name_fr: 'Début',
            human_name_en: 'Start',
            type: 'Date',
          },{
            name: 'end_at',
            human_name_fr: 'Fin',
            human_name_en: 'End',
            type: 'Date',
          }],
        )
        issue_klass = schema.klasses.create!(
          name: 'Issue',
          human_name_fr: 'Ticket',
          human_name_en: 'Issue',
          update_menu_items: false,
          icon: 'tasks',
          attrs_attributes: [{
            name: 'title',
            human_name_fr: 'Titre',
            human_name_en: 'Title',
            type: 'Text',
           },{
            name: 'description',
            human_name_fr: 'Description',
            human_name_en: 'Description',
            type: 'Text',
          },{
            name: 'state',
            human_name_fr: 'État',
            human_name_en: 'State',
            values_attributes: [{
              name: 'to_do',
              human_name_fr: 'À faire',
              human_name_en: 'To do',
            }, {
              name: 'started',
              human_name_fr: 'En cours',
              human_name_en: 'Started',
            }, {
              name: 'finished',
              human_name_fr: 'Terminé',
              human_name_en: 'Finished',
            }],
            type: 'Enum',
          }]
        )

        issues_sprint = issue_klass.associations.create!(
          name: 'sprint',
          human_name_fr: 'Sprint',
          human_name_en: 'Sprint',
          target_klass: sprint_klass,
          type: 'BelongsTo'
        )
        sprint_issues = sprint_klass.associations.create!(
          name: 'issues',
          human_name_fr: 'Tickets',
          human_name_en: 'Issues',
          target_klass: issue_klass,
          inverse_of: issues_sprint,
          type: 'HasMany'
        )
        issues_sprint.update(inverse_of: sprint_issues)
      end

      def self.create_menus(schema)
        menu_klass = "D::#{schema.name}::R::Menu".safe_constantize
        return unless menu_klass
        menu_klass.find_each do |menu|
          new_menu = menu.items.create!(
            label_fr: 'Tickets',
            label_en: 'Issues',
            icon: 'tasks',
            link: "/crm/#{schema.name.underscore}/kanban/issues", # TODO schema.name + issues klass name
            position: 99999,
          )
          menu.items.create!(
            label_fr: 'Sprint',
            label_en: 'Sprint',
            icon: 'tasks',
            link: "/crm/#{schema.name.underscore}/kanban/issues", # TODO schema.name + issues klass name
            position: 99999,
            parent_id: new_menu.id,
          )
          menu.items.create!(
            label_fr: 'Backlog',
            label_en: 'Backlog',
            icon: 'table',
            link: "/crm/#{schema.name.underscore}/kanban/issues", # TODO schema.name + issues klass name
            position: 99999,
            parent_id: new_menu.id,
          )
        end
      end

    end
  end
end
