module Virti::Acl::Patches::ContactsExportJobPatch
  private

  def contacts
    return @account.contacts.none unless virti_acl_contacts_module_allowed?

    Virti::Acl::ContactScope.new(
      scope: super,
      user: @account_user,
      account: @account
    ).perform
  end

  def virti_acl_contacts_module_allowed?
    Virti::Acl::ContactsModuleAccess.allowed?(user: @account_user, account: @account)
  end
end
