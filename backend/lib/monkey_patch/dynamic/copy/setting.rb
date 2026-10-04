ActiveSupport.on_load(:dynamic_copy_setting) do

  concerning :Permissions do
    included do
      include UneekPermission::ControlledKlass
    end
  end

end
