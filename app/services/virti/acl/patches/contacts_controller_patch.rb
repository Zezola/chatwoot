module Virti::Acl::Patches::ContactsControllerPatch
  CONTACTS_ACTIONS = [
    :index,
    :search,
    :import,
    :export,
    :active,
    :show,
    :filter,
    :contactable_inboxes,
    :destroy_custom_attributes,
    :create,
    :update,
    :destroy,
    :avatar
  ].freeze

  CONTACTS_ACTIONS.each do |action_name|
    define_method(action_name) do |*args, &block|
      return render_virti_acl_contacts_module_forbidden unless virti_acl_contacts_module_allowed?

      super(*args, &block)
    end
  end

  private

  def fetch_contacts(contacts)
    return contacts.none unless virti_acl_contacts_module_allowed?

    super(virti_acl_contact_scope(contacts))
  end

  def fetch_contacts_with_has_more(contacts)
    return [] unless virti_acl_contacts_module_allowed?

    super(virti_acl_contact_scope(contacts))
  end

  def fetch_contact
    return render_virti_acl_contacts_module_forbidden unless virti_acl_contacts_module_allowed?

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

  def virti_acl_contacts_module_allowed?
    Virti::Acl::ContactsModuleAccess.allowed?(user: Current.user, account: Current.account)
  end

  def render_virti_acl_contacts_module_forbidden
    render json: { error: 'Permission denied' }, status: :forbidden
  end
end
