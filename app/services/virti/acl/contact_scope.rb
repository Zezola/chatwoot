class Virti::Acl::ContactScope
  def initialize(scope:, user:, account:)
    @scope = scope
    @user = user
    @account = account
  end

  def perform
    return scope unless Virti::Acl.enabled?
    return scope unless user.is_a?(User)

    result = Virti::Acl::PermissionsResolver.new(user: user, account: account).resolve
    return scope if result.acl_source == 'default'
    return scope if result.permissions['pode_ver_aba_de_todas_conversas'] != false

    scope.where(id: visible_conversation_scope.select(:contact_id))
  end

  private

  attr_reader :scope, :user, :account

  def visible_conversation_scope
    Virti::Acl::ConversationScope.new(scope: account.conversations, user: user, account: account).perform
  end
end
