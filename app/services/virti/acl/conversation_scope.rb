module Virti
  module Acl
    class ConversationScope
      def initialize(scope:, user:, account:)
        @scope = scope
        @user = user
        @account = account
      end

      def perform
        return scope unless Virti::Acl.enabled?

        result = PermissionsResolver.new(user: user, account: account).resolve
        return scope if result.acl_source == 'default'
        return scope if result.permissions['pode_ver_aba_de_todas_conversas'] != false

        accessible_scope(result.permissions)
      end

      private

      attr_reader :scope, :user, :account

      def accessible_scope(permissions)
        assigned_to_user = scope.where(assignee_id: user.id)
        return assigned_to_user unless permissions['pode_ver_aba_de_nao_atribuidas']

        assigned_to_user.or(scope.where(assignee_id: nil))
      end
    end
  end
end
