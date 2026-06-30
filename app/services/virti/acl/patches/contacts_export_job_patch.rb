module Virti::Acl::Patches::ContactsExportJobPatch
  private

  def contacts
    Virti::Acl::ContactScope.new(
      scope: super,
      user: @account_user,
      account: @account
    ).perform
  end
end
