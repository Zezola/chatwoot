module Virti
  module Acl
    class NotificationPolicy
      def initialize(user:, account:, actor: nil, notification: nil)
        @user = user
        @account = account
        @actor = actor || notification&.primary_actor
      end

      def show?
        conversation = actor.is_a?(Conversation) ? actor : actor.try(:conversation)
        return true if conversation.blank?

        ConversationPolicy.new(user: user, account: account, conversation: conversation).show?
      end

      private

      attr_reader :user, :account, :actor
    end
  end
end
