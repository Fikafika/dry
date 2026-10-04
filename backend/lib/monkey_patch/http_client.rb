# HTTPClient embeds it own outdated certificates.
# See https://github.com/nahi/httpclient/issues/445 for a potential fix.
# To solve this, we use the same patch as Debian (https://anonscm.debian.org/git/pkg-ruby-extras/ruby-httpclient.git#542849f1b60e9c0cd24c328ad710b2a94cb42729).
require 'httpclient'

class HTTPClient
  class SSLConfig
    def load_trust_ca
      set_default_paths
      change_notify
    end
  end
end
