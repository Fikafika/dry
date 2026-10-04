class Crm
  class Table
    module Column
      class Modal < ::Modal

        render { content }

        param :klass
        param :search_query

        track_changes :klass, [:search_query, :columns]

        fires :columns_selection

        def title
          I18n.t('crm.choose_columns')
        end

        def body
          Selector(selected_columns: @selected_columns, klass: klass).on(:change) do |selected_columns|
            @selected_columns = selected_columns
            mutate
          end
        end

        def init
          init_selected_columns
          if klass
            observe klass.options_for_indexed_json
          end
        end

        def footer
          DIV(class: "d-flex") do
            select_all_button
          end
          DIV(class: 'd-flex flex-grow-1') do
          end

          DIV do
            super
          end
        end

        def confirm
          change_columns
          super
        end

        def cancel
          super
        end

        def change_columns
          if @selected_columns.present?
            search_query[:columns] ||= []
            search_query[:columns] = @selected_columns
          else
            search_query[:columns] = []
          end
          columns_selection!
        end

        def select_all_button
          DIV(class: "d-flex") do
            if all_paths.any?
              is_all_selected = (@selected_columns&.length == all_paths.length)
              BUTTON(class: "btn btn-light", type: "button") do
                is_all_selected ? I18n.t('shared.deselect_all') : I18n.t('shared.select_all')
              end.on(:click) do
                @selected_columns = is_all_selected ? [] : all_paths.dup
                mutate
              end
            end
          end
        end

        def all_paths
          @all_paths = nil if klass_changed?
          @all_paths ||= Selector.all_paths_for(klass)
        end

        def select_all
          @selected_columns = klass.datatable_column_names.dup
          mutate
        end

        def unselect_all
          @selected_columns = []
          mutate
        end

        def all_selected?
          @selected_columns&.length == klass.datatable_column_names.length
        end

        def select_all_button_for_association
          # TODO
          #BUTTON(class:"btn btn-light", type:"button") do
            #!all_selected? ? I18n.t('shared.select_all') : I18n.t('shared.deselect_all')
          #end.on(:click) do |event|
            #all_selected? ? unselect_all : select_all
          #end
        end

        def init_selected_columns
          @selected_columns = nil if search_query_columns_changed? || klass_changed?
          return if @selected_columns
          @selected_columns = search_query.dig(:columns)&.dup || []
        end

      private

        def default_size
          'xl'
        end

      end
    end
  end
end
