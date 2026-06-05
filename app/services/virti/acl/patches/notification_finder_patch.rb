module Virti
  module Acl
    module Patches
      module NotificationFinderPatch
        private

        def find_all_notifications
          super
          return @notifications unless Virti::Acl.enabled?

          allowed_conversation_ids = Virti::Acl::ConversationScope.new(
            scope: current_account.conversations,
            user: current_user,
            account: current_account
          ).perform.select(:id)

          @notifications = @notifications.where(
            'notifications.primary_actor_type != ? OR notifications.primary_actor_id IN (?)',
            'Conversation',
            allowed_conversation_ids
          )
        end
      end
    end
  end
end
