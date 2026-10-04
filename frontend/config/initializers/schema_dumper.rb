ActiveSupport.on_load(:active_record) do

  ActiveRecord::SchemaDumper.ignore_tables << /\Adynamic_/
  ActiveRecord::SchemaDumper.ignore_tables << /\Ad_/
  ActiveRecord::SchemaDumper.ignore_tables << /\Auneek_doc_gen_/
  ActiveRecord::SchemaDumper.ignore_tables += [
    'active_storage_attachments',
    'active_storage_blobs',
    'active_storage_variant_records',
    'cas_session_tickets',
    'communities',
    'memberships',
    'users',
    'version_associations',
    'sessions',
  ]

end
