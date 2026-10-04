class Crm
  class FileManager < Crm::Index::Base
    include Crm::Routes::Helpers

    render(DIV, class: 'crm-index') do
      global_toolbar
      edit_query_dialog

      Crm::FileManager::View(
        klass: klass,
        regular_file_klass: regular_file_klass,
        directory_assoc: directory_assoc,
        directory_id: directory_id,
        reload: @reload,
      ).on(:change_directory) do |dir|
        change_directory(dir)
      end.on(:edit) do |file|
        edit(file)
      end
    end

    def regular_file_klass
      @regular_file_klass ||= klass.base_class.subclasses.detect{|k| k != directory_klass } # TODO retrieve from dynamic_layout element
    end

    def directory_klass
      @directory_klass ||= klass.reflect_on_association(directory_assoc)&.klass
    end

    def directory_assoc
      # TODO retrieve from dynamic_layout element
      @directory_assoc ||= ['directory', 'folder', 'dossier'].detect do |n|
        klass.reflect_on_association(n)
      end
    end

    def directory_id
      search_query.dig(:filters, directory_assoc, :contains_id)
    end

    def edit(file)
      App.history.push(App.location.add_params('rp' => edit_url(file.class, file.id)))
    end

    def change_directory(dir)
      if dir&.id
        search_query[:filters] ||= {}
        search_query[:filters][directory_assoc] = {contains_id: dir.id}
      else
        search_query[:filters]&.delete(directory_assoc)
        search_query.delete(:filters) if search_query[:filters]&.empty?
      end
      search
    end

    def global_toolbar_right
      Portal(id: 'global-toolbar-right') do
        Toolbar::Dropdown(text: I18n.t('shared.new'), icon: 'plus', btn_params: { class: "btn btn-transparent-primary shadow-none" }) do
          if regular_file_klass
            Toolbar::Dropdown::Item(target: new_url(regular_file_klass), text: klass.model_name.human, icon: regular_file_klass.icon, "data-open-panel": 'right', variant: 'primary')
          end
          if directory_klass
            Toolbar::Dropdown::Item(target: new_url(directory_klass), text: directory_klass.model_name.human, icon: directory_klass.icon, "data-open-panel": 'right', variant: 'primary')
          end
        end
        GroupDrop(variant: 'primary') do
          toolbar_delete_button(disabled: true)
        end
      end
    end

    def new_url(klass)
      return super unless directory_id
      return "#{index_url(klass)}/new?params[#{klass.name.demodulize.underscore}][#{directory_assoc}][id]=#{directory_id}"
    end

    def reload
      @reload ||= 0
      @reload += 1
    end

  end
end
