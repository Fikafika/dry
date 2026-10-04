# frozen_string_literal: true

load "#{Gem.loaded_specs['dynamic-doc_gen'].full_gem_path}/app/models/dynamic/doc_gen/generation.rb"

module Dynamic
  module DocGen
    class Generation
      attribute :id, default: ->{ActiveRecord::Base.connection.select_value('SELECT uuid_generate_v7()')}

      def as_json(options = nil)
        {
          'id' => self.id,
          'klass_id' => klass.name,
          'template_id' => self.template.id,
          'super_merge' => !!self.super_merge,
          'merge' => !!self.merge,
          'attachment' => self.attachment,
          'output_name' => self.output_name,
          'options' => self.options,
          'prevent_progress_success' => self.prevent_progress_success,
        }.as_json(options)
      end
    end
  end
end
