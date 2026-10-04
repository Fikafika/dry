if RUBY_ENGINE == 'opal'

  class Membership < ::HyperResource::Base
    belongs_to :user, inverse_of: :memberships
    def community
      user.communities.detect{|c| c.id == community_id}
    end
  end

else

  class Membership < ::ApplicationRecord
  end

end
