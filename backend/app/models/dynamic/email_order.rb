module Dynamic
  module EmailOrder

    class Base < ActiveRecord::Base
      include Dynamic::Mount

      define_table do |t| # if you change this definition you must do a migration of all mounted tables
        t.string     :name
        t.string     :klass
        t.string     :schema
        t.json       :filters
      end

      after_mount do
        has_many :types, class_name: 'Type', inverse_of: :email_order, foreign_key: 'email_order_id', dependent: :destroy
        accepts_nested_attributes_for :types, allow_destroy: true
      end

      def sorted_types
        types.map {|t| [t.position, t.tag]}.sort do |a, b|
          a_nil = a.second.nil?
          b_nil = b.second.nil?
          if a_nil || b_nil
            a_nil ? 1 : -1
          else
            a <=> b
          end
        end
      end
    end

    class Type < ActiveRecord::Base
      self.table_name = 'email_order_types'

      include Dynamic::Mount

      define_table do |t|
        t.string     :tag
        t.integer    :position
        t.belongs_to :email_order, type: :uuid
      end

      after_mount do
        belongs_to :email_order, class_name: 'EmailOrder::Base', inverse_of: :types, touch: true
      end
    end
  end
end
