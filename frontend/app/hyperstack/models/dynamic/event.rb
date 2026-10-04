module Dynamic
  module Event
    module Feature; extend ActiveSupport::Concern

    end

    module Event; extend ActiveSupport::Concern

      def self.load_constants(concern, schema)
        klass = schema.klasses.detect {|k| k.id == concern.klass_id}

        singleton_method_name_by_option_name = {
          'starting_date' => :event_start_date_name,
          'ending_date' => :event_end_date_name,
          'cancelation_date' => :event_cancel_date_name,
        }

        singleton_method_name_by_option_name.each do |option_name, method_name|
          option_value = concern.options.detect{|o| o.name == option_name}&.value
          mapped_attr = option_value ? klass.attrs.detect {|a| a.id == option_value} : nil
          mapped_attr_name = mapped_attr ? mapped_attr.name : nil
          klass.const.define_singleton_method(method_name) do
            mapped_attr_name
          end
        end
      end
    end

    module Indisponibility; extend ActiveSupport::Concern

      def self.load_constants(concern, schema)
        klass = schema.klasses.detect {|k| k.id == concern.klass_id}
        option_value = concern.options.detect{|o| o.name == 'indisponibility_assoc'}&.value
        mapped_assoc = option_value ? klass.associations.detect {|a| a.id == option_value} : nil
        mapped_assoc_name = mapped_assoc ? mapped_assoc.name : nil
        klass.const.define_singleton_method('event_indisponibility_association_name') do
          mapped_assoc_name
        end
      end
    end
  end
end