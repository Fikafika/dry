# frozen_string_literal: true

load "#{Gem.loaded_specs['dynamic-doc_gen'].full_gem_path}/app/models/dynamic/doc_gen/merge/file.rb"


module Dynamic
  module DocGen
    module Merge
      class File

        concerning :Permissions do
          included do
            include UneekPermission::ControlledKlass

            def associations_for_uneek_permissions
              nil
            end
          end
        end

      end
    end
  end
end