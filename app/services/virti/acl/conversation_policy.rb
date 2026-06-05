module Virti
  module Acl
    class ConversationPolicy
      def initialize(user:, account:, conversation:)
        @user = user
        @account = account
        @conversation = conversation
      end

      def show?
        return true unless Virti::Acl.enabled?
        return true unless user.is_a?(User)

        result = PermissionsResolver.new(user: user, account: account).resolve
        return true if result.acl_source == 'default'
        return true if result.permissions['pode_ver_aba_de_todas_conversas'] != false
        return true if conversation.assignee_id == user.id
        return true if result.permissions['pode_ver_aba_de_nao_atribuidas'] && conversation.assignee_id.blank?

        false
      end

      private

      attr_reader :user, :account, :conversation
    end
  end
end
