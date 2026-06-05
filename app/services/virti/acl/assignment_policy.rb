module Virti
  module Acl
    class AssignmentPolicy
      def initialize(user:, account:)
        @user = user
        @account = account
      end

      def assign?
        return true unless Virti::Acl.enabled?
        return true unless user.is_a?(User)

        result = PermissionsResolver.new(user: user, account: account).resolve
        return true if result.acl_source == 'default'

        result.permissions['pode_ver_menu_de_acoes_da_conversa'] != false &&
          result.permissions['pode_ver_opcoes_de_atribuicao_no_menu_de_contexto'] != false
      end

      private

      attr_reader :user, :account
    end
  end
end
