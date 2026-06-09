module Virti
  module Acl
    module Patches
      module ActionCableBroadcastJobPatch
        CONVERSATION_EVENT_NAMES = [
          'message.created',
          'message.updated',
          'first.reply.created',
          'conversation.created',
          'conversation.updated',
          'conversation.read',
          'conversation.status_changed',
          'conversation.typing_on',
          'conversation.typing_off',
          'assignee.changed',
          'team.changed',
          'conversation.contact_changed',
          'conversation.mentioned'
        ].freeze

        private

        def broadcast_to_members(members, event_name, broadcast_data)
          super(filtered_members(members, event_name, broadcast_data), event_name, broadcast_data)
        end

        def filtered_members(members, event_name, broadcast_data)
          return members unless Virti::Acl.enabled?
          return members unless CONVERSATION_EVENT_NAMES.include?(event_name.to_s)

          payload = broadcast_data.with_indifferent_access
          account = Account.find_by(id: payload[:account_id])
          conversation = conversation_from_payload(account, payload)
          return [] if account.blank? || conversation.blank?

          allowed_tokens_for_conversation(Array(members).compact.uniq, account, conversation)
        end

        def conversation_from_payload(account, payload)
          return if account.blank?

          display_id = payload[:conversation_id] || payload.dig(:conversation, :id) || payload[:id]
          return if display_id.blank?

          account.conversations.find_by(display_id: display_id)
        end

        def allowed_tokens_for_conversation(tokens, account, conversation)
          users_by_token = User.where(pubsub_token: tokens).index_by(&:pubsub_token)
          contact_tokens = ContactInbox.where(pubsub_token: tokens, contact_id: conversation.contact_id).pluck(:pubsub_token)

          tokens.select do |token|
            user = users_by_token[token]
            next contact_tokens.include?(token) if user.blank?

            Virti::Acl::ConversationPolicy.new(user: user, account: account, conversation: conversation).show?
          end
        end
      end
    end
  end
end
