module Virti::Acl::Patches::ContactsFilterServicePatch
  def base_relation
    Virti::Acl::ContactScope.new(
      scope: super,
      user: @user,
      account: @account
    ).perform
  end
end
