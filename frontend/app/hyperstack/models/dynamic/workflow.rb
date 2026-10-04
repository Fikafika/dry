module Dynamic

  module Workflow

    module Feature
      def self.load_constants(schema)
        schema.const_reserved_klass("Workflow::ManualTrigger", ::Dynamic::Workflow::ManualTrigger)
      end
    end

    class ManualTrigger < Dynamic::Base # abstract
      define_api_path # /api/d/uneek/r__workflow__manual_triggers

      translates :name
      globalize_accessors
    end

  end

end
