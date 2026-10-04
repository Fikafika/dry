ActiveSupport.on_load(:dynamic_copy_mapping) do

  concerning :Permissions do
    included do
      include UneekPermission::ControlledKlass
    end
  end

end
