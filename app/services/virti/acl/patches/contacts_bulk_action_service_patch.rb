module Virti::Acl::Patches::ContactsBulkActionServicePatch
  private

  def ids
    contact_ids = super
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
end
