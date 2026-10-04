class Crm
  class FileManager
    class View < HyperComponent
      include Router::Helpers

      param :klass
      param :regular_file_klass
      param :directory_assoc

      param :directory_id, default: nil
      param :reload, default: nil

      fires :change_directory
      fires :edit

      render do
        if files.loading?
          loading_placeholder
        elsif files.loaded?
          DIV(class: 'grid-fluid grid-fluid-12 grid-gap-1 pt-2') do
            render_files
          end
        end
      end

      def files
        if @previous_directory_id != directory_id || reload != @previous_reload
          @previous_directory_id = directory_id
          @previous_reload = reload
          @directory = nil
          @files = nil
          klass.clear_cache
        end
        observe @files ||= klass.includes(preview: Dynamic::Base.active_storage_includes)
          .where(directory_assoc_id => directory_id)
          .nilify_blanks(directory_assoc_id)
          .order(name: 'asc')
          .limit(1000)
          .all
      end

      def directory_assoc_id
        "#{directory_assoc}_id"
      end

      def loading_placeholder
        I(class: 'm-3 fa fa-spinner fa-2x fa-pulse')
      end

      def render_files
        list.each do |f|
          DIV(class: 'position-relative') do
            DIV(class: 'card m-3 border-0 cursor-pointer') do
              DIV(class: 'card-img-top text-center') do
                Icon(file: f)
              end
              DIV(class: 'card-body text-center text-break p-2') do
                file_name(f)
              end
            end.on(:click) do |e|
              e.stop_propagation
              change_directory_or_edit(f)
            end
            DIV(class: 'position-absolute fa fa-pen p-1 mr-2 mt-2 rounded bg-primary cursor-pointer', style: {top: 0, right: 0}) do
            end.on(:click) do |e|
              e.stop_propagation
              edit!(f)
            end
          end
        end
      end

      class Icon < HyperComponent
        param :file

        render do
          @photo_errors ||= {}
          signed_id = file.try(:preview)&.signed_id
          if file.try(:preview)&.attached? && !@photo_errors[signed_id]
            filename = file.preview.filename
            IMG(
              style: {width: '4em', height: '4em', 'object-fit': 'cover'},
              src: "#{::HyperResource::Base.api_prefix}/files/representations/#{signed_id}/preview/preview.png",
              onError: Proc.new{ @photo_errors[signed_id] = true; mutate },
            )
          else
            SPAN(class: "fa fa-#{file.class.icon} fa-regular fa-4x"){}
          end
        end
      end

      def file_name(file)
        file.send(file.class.name_attribute || :name)
      end

      def list
        (p = parent) ? [p] + files : files
      end

      def directory
        return unless directory_id
        observe @directory ||= klass.find(directory_id)
      end

      def parent
        return (directory_id && directory_klass) ? directory_klass.new(name: '..', id: parent_id) : nil
      end

      def parent_id
        return unless directory&.loaded? && !directory.not_found?
        return directory.send("#{directory_assoc}_id")
      end

      def directory_klass
        @directory_klass ||= klass.reflect_on_association(directory_assoc).klass
      end

      def change_directory_or_edit(file)
        case file
        when directory_klass
          change_directory!(file)
        when regular_file_klass
          edit!(file)
        end
      end

    end

  end
end
