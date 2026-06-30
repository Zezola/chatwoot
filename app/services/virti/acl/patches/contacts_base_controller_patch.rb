module Virti::Acl::Patches::ContactsBaseControllerPatch
  private

  def ensure_contact
    return render_virti_acl_contacts_module_forbidden unless virti_acl_contacts_module_allowed?

    super
    enforce_virti_acl_contact_access
  end

  def enforce_virti_acl_contact_access
    return if performed?
    return if Virti::Acl::ContactPolicy.new(user: Current.user, account: Current.account, contact: @contact).show?

    render json: { error: 'Permission denied' }, status: :forbidden
  end

  def virti_acl_contacts_module_allowed?
    Virti::Acl::ContactsModuleAccess.allowed?(user: Current.user, account: Current.account)
  end

  def render_virti_acl_contacts_module_forbidden
    render json: { error: 'Permission denied' }, status: :forbidden
  end
end
