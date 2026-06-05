module Virti
  module Acl
    module Patches
      module PermissionFilterServicePatch
        def perform
          filtered_scope = super
          return filtered_scope unless Virti::Acl.enabled?

          Virti::Acl::ConversationScope.new(scope: filtered_scope, user: user, account: account).perform
        end
      end
    end
  end
end
