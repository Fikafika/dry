if RUBY_ENGINE == 'opal'

  class Community < ::HyperResource::Base

    def self.api_path
      "#{api_prefix}/communities"
    end

    belongs_to :theme, class_name: 'Dynamic::Theme'

    def update_appearance
      if theme_id
        Dynamic::Theme.includes(schema: 1).find_without_cache(theme_id) do |t|
          App.change_theme(t.path, true)
        end
      else
        App.change_theme(nil)
      end
    end

  end

else

  class Community < ::ApplicationRecord
  end

end
