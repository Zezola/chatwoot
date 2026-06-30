module Virti::Acl::Patches::ContactsBulkActionServicePatch
  private

  def ids
    contact_ids = super
    return [] unless virti_acl_contacts_module_allowed?
    return contact_ids unless virti_acl_restrict_contact_ids?

    Virti::Acl::ContactScope.new(
      scope: @account.contacts.where(id: contact_ids),
      user: @user,
      account: @account
    ).perform.pluck(:id)
  end

  def virti_acl_restrict_contact_ids?
    return false unless Virti::Acl.enabled?
    return false unless @user.is_a?(User)

    result = Virti::Acl::PermissionsResolver.new(user: @user, account: @account).resolve
    return false if result.acl_source == 'default'

    result.permissions['pode_ver_aba_de_todas_conversas'] == false
  end

  def virti_acl_contacts_module_allowed?
    Virti::Acl::ContactsModuleAccess.allowed?(user: @user, account: @account)
  end
end
