ActiveSupport.on_load(:dynamic_schema_attribute_base) do

  safe_enum :editor, {}, validate: false

  concerning :AttributeChangeUpdateDefaultForms do
    included do
      attr_accessor :skip_create_default_forms
      after_create :update_default_forms, unless: :skip_create_default_forms
      after_destroy :update_default_forms

      def update_default_forms
        klass.update_default_form(action: :new, mode: :input, attr: self)
        klass.update_default_form(action: :edit, mode: :edit_in_place, attr: self)
        klass.update_default_form(action: :show, mode: :read_only, attr: self)
        klass.update_default_form(action: :submit_all, mode: :input, attr: self)
      end
    end
  end

  concerning :Protocols do

    included do
      PROTOCOLS_TO_I = Hash.new
      PROTOCOLS_TO_I[:http]  = '00000001'.to_i(2)
      PROTOCOLS_TO_I[:mailto] = '00000010'.to_i(2)
      PROTOCOLS_TO_I[:tel] = '00000100'.to_i(2)
      PROTOCOLS_TO_I[:sms] = '00001000'.to_i(2)
      PROTOCOLS_TO_I.freeze
      I_TO_PROTOCOLS = PROTOCOLS_TO_I.invert.freeze

      PROTOCOLS = PROTOCOLS_TO_I.keys.map{|m| m.to_sym }
      PROTOCOLS.freeze

      scope :with_protocols, -> (protocol) {
        a = protocol_to_db(protocol)
        where("(#{self.table_name}.protocol & #{a} = #{a})")
      }

      scope :with_protocol, -> (protocol) { with_protocol(Array(protocol)) }
    end

    class_methods do
      def protocols_to_db(integer_or_array)
        return 0 unless integer_or_array
        if integer_or_array.is_a?(Integer)
          return integer_or_array
        else
          return integer_or_array.map{|a| PROTOCOLS_TO_I[a.to_sym]}.inject(&:|) || 0
        end
      end

      def db_to_protocols(i)
        result = []
        PROTOCOLS_TO_I.each do |k,v|
          result << k if (i & v == v)
        end
        return result
      end
    end

    def protocols
      self.class.db_to_protocols(read_attribute(:protocols))
    end

    def protocols=(value)
      write_attribute(:protocols, self.class.protocols_to_db(value))
    end

  end

  concerning :NamePreviouslyWas do # remove this concern after migration to rails 6.1+
    def name_previously_was
      self.previous_changes['name'].try(:first)
    end
  end

  include ::Dynamic::Schema::Base::ChangeUpdateAutocompleteFilters

  concerning :NormalizeAll do

    def normalize_all_records_asynchronously
      Dynamic::Record::Normalization::Worker.perform_async(
        ["#{self.klass.const_absolute_name}-*"],
        {'with_deleted' => true, 'attrs' => [self.name]}
      )
    end

  end

end
