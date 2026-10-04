module Dynamic
  module Sms
    module Feature; extend ActiveSupport::Concern

      def self.load_constants(schema)
        sms_feature = schema.features.detect{|f| f.name == "Dynamic::Sms::Feature"}

        return unless sms_feature

        phone_klass = sms_feature.options&.detect{|o| o.name == "phone_klass" }&.value
        schema.const.define_singleton_method(:sms_phone_klass_name) do
          phone_klass ? phone_klass['name'] : nil
        end
        owner_association_for_phone = sms_feature.options&.detect{|o| o.name == "owner_association" }&.value
        schema.const.define_singleton_method(:sms_owner_association_name_for_phone) do
          owner_association_for_phone ? owner_association_for_phone['name'] : nil
        end

        sms_concern = sms_feature.concerns&.where(name: 'Sms').first
        owner_association_for_sms = sms_concern&.options&.detect{|o| o.name == "owner_association" }&.value
        schema.const.define_singleton_method(:sms_owner_association_name_for_sms) do
          owner_association_for_sms ? owner_association_for_sms['name'] : nil
        end

        phone_association_for_sms = sms_concern&.options&.detect{|o| o.name == "phone_association" }&.value
        schema.const.define_singleton_method(:sms_phone_association_name_for_sms) do
          phone_association_for_sms ? phone_association_for_sms['name'] : nil
        end

        phone_number_attribute_for_sms = sms_concern&.options&.detect{|o| o.name == "phone_number_attribute" }&.value
        schema.const.define_singleton_method(:sms_phone_number_attribute_name_for_sms) do
          phone_number_attribute_for_sms ? phone_number_attribute_for_sms['name'] : nil
        end
      end
    end

    module Sms; extend ActiveSupport::Concern

      class_methods do

        def compute_initial_form_params(params)
          classify_schema_name = "D::#{params[:schema]&.classify_permalink}"
          const_schema = classify_schema_name.safe_constantize
          return unless const_schema
          phone_klass = "#{classify_schema_name}::#{const_schema.sms_phone_klass_name}".safe_constantize
          owner_assoc_name_for_phone = const_schema.sms_owner_association_name_for_phone
          return unless phone_klass || owner_assoc_name_for_phone

          owner_assoc_name_for_sms = const_schema.sms_owner_association_name_for_sms
          phone_assoc_name_for_sms = const_schema.sms_phone_association_name_for_sms
          return unless owner_assoc_name_for_sms || phone_assoc_name_for_sms

          return Proc.new do |callback|
            phone_klass.includes(owner: 1).find(params[:target_record_id]) do |phone|
              return unless callback
              params_ = {
                "sms@0.#{phone_assoc_name_for_sms}@0": {
                  id: params[:target_record_id],
                },
                "sms@0.#{owner_assoc_name_for_sms}@0": {
                  id: phone.send("#{owner_assoc_name_for_phone}_id"),
                  type: phone.send("#{owner_assoc_name_for_phone}_type"),
                }
              }
              data = {
                'sms': {
                  owner_assoc_name_for_sms => [phone.send(owner_assoc_name_for_phone)],
                  phone_assoc_name_for_sms => [phone],
                },
              }
              callback.call(params_, data)
            end
          end
        end

      end

    end

    module History; extend ActiveSupport::Concern
    end

    module Owner; extend ActiveSupport::Concern
    end
  end
end