class Settings

  class Schema

    class Migrations < ::Settings::Schema::Base

      render{ content }

      def klass
        ::Dynamic::Schema::Migration::Base
      end

      class EditPanel < ::Settings::Schema::EditPanel

        render { content }

        def form
        end

      end

    end

  end

end
