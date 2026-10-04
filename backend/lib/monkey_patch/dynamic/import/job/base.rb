ActiveSupport.on_load(:dynamic_import_job_base) do
  include HyperResourceBroadcastUpdate
end
