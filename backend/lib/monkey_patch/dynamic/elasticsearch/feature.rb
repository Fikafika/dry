ActiveSupport.on_load(:dynamic_elasticsearch_feature) do

  ::Dynamic::Elasticsearch::Feature::DynamicRecord.indexable_virtual_attribute :creator_name, -> (o){
    o._creator&.name_or_login
  }, type: 'String',  preloads: {_creator: {}} # TODO implement preloads !!!

end
