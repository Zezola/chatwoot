module Virti::Acl::Patches::ContactsControllerPatch
  private

  def fetch_contacts(contacts)
    super(virti_acl_contact_scope(contacts))
  end

  def fetch_contacts_with_has_more(contacts)
    super(virti_acl_contact_scope(contacts))
  end

  def fetch_contact
    super
    enforce_virti_acl_contact_access
  end

  def virti_acl_contact_scope(scope)
    Virti::Acl::ContactScope.new(
      scope: scope,
      user: Current.user,
      account: Current.account
    ).perform
  end

  def enforce_virti_acl_contact_access
    return if performed?
    return if Virti::Acl::ContactPolicy.new(user: Current.user, account: Current.account, contact: @contact).show?

    render json: { error: 'Permission denied' }, status: :forbidden
  end
end
