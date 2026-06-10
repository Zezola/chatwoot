module Virti
  module Acl
    module Patches
      module ActionCableListenerPatch
        CONVERSATION_REMOVED_FROM_SCOPE = 'conversation.removed_from_scope'.freeze

        def assignee_changed(event)
          super
          broadcast_removed_from_scope(event)
        end

        private

        def broadcast_removed_from_scope(event)
          conversation, account = extract_conversation_and_account(event)
          user = previous_assignee(event)
          return if user.blank?
          return if Virti::Acl::ConversationPolicy.new(user: user, account: account, conversation: conversation).show?

          ActionCableBroadcastJob.perform_later(
            [user.pubsub_token],
            CONVERSATION_REMOVED_FROM_SCOPE,
            account_id: account.id,
            id: conversation.display_id
          )
        end

        def previous_assignee(event)
          assignee_change = assignee_change(event)
          return if assignee_change.blank?

          User.find_by(id: assignee_change.first)
        end

        def assignee_change(event)
          changed_attributes = event.data[:changed_attributes] || {}
          changed_attributes[:assignee_id] || changed_attributes['assignee_id']
        end
      end
    end
  end
end
