if RUBY_ENGINE == 'opal'
  class ApplicationRecord
  end
else
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
