module Virti::Acl::Patches::ContactsBaseControllerPatch
  private

  def ensure_contact
    super
    enforce_virti_acl_contact_access
  end

  def enforce_virti_acl_contact_access
    return if performed?
    return if Virti::Acl::ContactPolicy.new(user: Current.user, account: Current.account, contact: @contact).show?

    render json: { error: 'Permission denied' }, status: :forbidden
  end
end
