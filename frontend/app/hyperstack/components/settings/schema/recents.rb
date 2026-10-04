class Settings
  class Schema
    class Recents < Base

      include Hyperstack::Router::Helpers

      render { content }

      include ::Settings::Recents::Concern

    end
  end

end

