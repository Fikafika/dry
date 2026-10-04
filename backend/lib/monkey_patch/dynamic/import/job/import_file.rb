ActiveSupport.on_load(:dynamic_import_job_import_file) do
  concerning :ProcessBufferWithModelDependency do
    included do
      def process_buffer
        continue = nil
        ::ModelDependency.with_dependencies_computed_later do
          continue = super
        end
        return continue
      end
    end
  end

  concerning :Versioning do

    def process
      set_paper_trail_controller_info
      super
    end

    def set_paper_trail_controller_info
      ::PaperTrail.request.controller_info.merge!(
        source_type: 'Dynamic::Import::Setting',
        source_id: self.setting_id,
      )
    end

  end

end
