module Virti::Acl::Patches::SearchServicePatch
  private

  def filter_conversations
    relation = super
    return relation unless restrict_by_conversation_acl?

    relation.where(conversations: { assignee_id: allowed_assignee_ids })
  end

  def message_base_query
    relation = super
    return relation unless restrict_by_conversation_acl?

    relation.where(conversation_id: acl_conversations.select(:id))
  end

  def filter_contacts
    relation = super
    return relation unless restrict_by_conversation_acl?

    relation.where(id: acl_conversations.select(:contact_id))
  end

  def restrict_by_conversation_acl?
    Virti::Acl.enabled? && acl_permissions['pode_ver_aba_de_todas_conversas'] == false
  end

  def can_view_unassigned_conversations?
    acl_permissions['pode_ver_aba_de_nao_atribuidas'] == true
  end

  def allowed_assignee_ids
    return [current_user.id, nil] if can_view_unassigned_conversations?

    current_user.id
  end

  def acl_conversations
    current_account.conversations.where(inbox_id: acl_accessible_inbox_ids, assignee_id: allowed_assignee_ids)
  end

  def acl_accessible_inbox_ids
    @acl_accessible_inbox_ids ||= if acl_account_user&.administrator?
                                    current_account.inboxes.select(:id)
                                  else
                                    current_user.inboxes.where(account_id: current_account.id).select(:id)
                                  end
  end

  def acl_account_user
    @acl_account_user ||= current_account.account_users.find_by(user: current_user)
  end

  def acl_permissions
    @acl_permissions ||= Virti::Acl::PermissionsResolver.new(user: current_user, account: current_account).resolve.permissions
  end
end
