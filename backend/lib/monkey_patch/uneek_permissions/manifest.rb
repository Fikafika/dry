ActiveSupport.on_load(:uneek_permission_manifest) do

  concerning :AssociateCommunity do
    included do
      belongs_to :community, class_name: 'Community', optional: true
    end
  end

end
