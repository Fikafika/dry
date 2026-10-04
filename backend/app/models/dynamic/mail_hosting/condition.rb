module Dynamic
  module MailHosting
    class Condition < ActiveRecord::Base

      self.abstract_class = true

      include Dynamic::Mount

      define_table do |t|
        t.belongs_to :rule, type: :uuid
        t.string :attr
        t.string :operator
        t.string :value
      end

      after_mount do
        belongs_to :rule, class_name: "Rule", inverse_of: :conditions, touch: true
      end

      def json_operator
        operator
      end


    end
  end
end