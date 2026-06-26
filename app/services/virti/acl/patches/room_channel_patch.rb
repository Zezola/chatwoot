module Virti::Acl::Patches::RoomChannelPatch
  private

  def broadcast_presence
    return super unless Virti::Acl.enabled?
    return if @current_account.blank?

    data = { account_id: @current_account.id, users: ::OnlineStatusTracker.get_available_users(@current_account.id) }
    data[:contacts] = filtered_available_contacts if @current_user.is_a?(User)

    ActionCable.server.broadcast(pubsub_token, { event: 'presence.update', data: data })
  end

  def filtered_available_contacts
    available_contacts = ::OnlineStatusTracker.get_available_contacts(@current_account.id)
    return available_contacts if available_contacts.blank?

    visible_contact_ids = Virti::Acl::ContactScope.new(
      scope: @current_account.contacts.where(id: available_contacts.keys),
      user: @current_user,
      account: @current_account
    ).perform.pluck(:id).map(&:to_s)

    available_contacts.slice(*visible_contact_ids)
  end
end
