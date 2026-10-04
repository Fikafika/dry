module Dynamic
  module Knewsletter
    class RecipientPath < ActiveRecord::Base

      include Dynamic::Mount

      define_table do |t| # if you change this definition you must do a migration of all mounted tables
        t.string     :name
        t.string     :formula
        t.string     :klass
        t.string     :schema
      end
    end
  end
end
