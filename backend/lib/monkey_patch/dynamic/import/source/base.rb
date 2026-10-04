ActiveSupport.on_load(:dynamic_import_source_base) do

  concerning :Permissions do
    included do
      include UneekPermission::ControlledKlass

      def associations_for_uneek_permissions
        nil
      end
    end
  end

end