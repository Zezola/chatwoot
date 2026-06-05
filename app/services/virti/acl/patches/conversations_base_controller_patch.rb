module Virti
  module Acl
    module Patches
      module ConversationsBaseControllerPatch
        def conversation
          super
          enforce_virti_acl_conversation_access
        end

        private

        def enforce_virti_acl_conversation_access
          return if performed?
          return if Virti::Acl::ConversationPolicy.new(user: Current.user, account: Current.account, conversation: @conversation).show?

          render json: { error: 'Permission denied' }, status: :forbidden
        end
      end
    end
  end
end
