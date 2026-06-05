module Virti
  module Acl
    def self.enabled?
      ENV.fetch('VIRTI_ACL_ENABLED', 'true') == 'true'
    end
  end
end
