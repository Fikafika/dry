module Dynamic
  module Vcard
    module Feature; end
    module Base; extend ActiveSupport::Concern; end
    module Individual; include Base; end
    module Group; include Base; end
    module Org; include Base; end
  end
end
