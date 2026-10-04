ActiveSupport.on_load(:dynamic_schema_option_base) do

  def record_as_deep_json(options = {}, secure = true)
    as_json(options)
  end

end
