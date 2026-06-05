module Virti
  module Acl
    module Patches
      module NotificationBuilderPatch
        private

        def user_can_access_conversation?
          return false unless super

          Virti::Acl::NotificationPolicy.new(user: user, account: account, actor: primary_actor).show?
        end
      end
    end
  end
end
