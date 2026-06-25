module Virti::Acl::Patches::ActionCableListenerPatch
  CONVERSATION_REMOVED_FROM_SCOPE = 'conversation.removed_from_scope'.freeze

  def notification_created(event)
    return unless notification_visible?(event)

    super
  end

  def notification_updated(event)
    return unless notification_visible?(event)

    super
  end

  def assignee_changed(event)
    super
    broadcast_removed_from_scope(event)
  end

  def contact_created(event)
    return super unless Virti::Acl.enabled?

    contact, account = extract_contact_and_account(event)
    broadcast_contact_event(account, contact, Events::Types::CONTACT_CREATED, contact.push_event_data)
  end

  def contact_updated(event)
    return super unless Virti::Acl.enabled?

    contact, account = extract_contact_and_account(event)
    broadcast_contact_event(account, contact, Events::Types::CONTACT_UPDATED, contact.push_event_data)
  end

  def contact_merged(event)
    return super unless Virti::Acl.enabled?

    contact, account = extract_contact_and_account(event)
    broadcast_contact_event(account, contact, Events::Types::CONTACT_MERGED, contact.push_event_data)
  end

  def contact_deleted(event)
    return super unless Virti::Acl.enabled?

    contact_data = event.data[:contact_data]
    account = Account.find_by(id: contact_data[:account_id])
    return if account.blank?

    tokens = contact_event_tokens(account, contact_id: contact_data[:id])
    broadcast(account, tokens, Events::Types::CONTACT_DELETED, contact_data)
  end

  private

  def broadcast_contact_event(account, contact, event_name, payload)
    tokens = contact_event_tokens(account, contact: contact)
    broadcast(account, tokens, event_name, payload)
  end

  def contact_event_tokens(account, contact: nil, contact_id: nil)
    account.users.filter_map do |user|
      next unless Virti::Acl::ContactPolicy.new(user: user, account: account, contact: contact, contact_id: contact_id).show?

      user.pubsub_token
    end
  end

  def broadcast_removed_from_scope(event)
    conversation, account = extract_conversation_and_account(event)
    user = previous_assignee(event)
    return if user.blank?
    return if Virti::Acl::ConversationPolicy.new(user: user, account: account, conversation: conversation).show?

    ActionCableBroadcastJob.perform_later(
      [user.pubsub_token],
      CONVERSATION_REMOVED_FROM_SCOPE,
      account_id: account.id,
      id: conversation.display_id
    )
  end

  def previous_assignee(event)
    assignee_change = assignee_change(event)
    return if assignee_change.blank?

    User.find_by(id: assignee_change.first)
  end

  def assignee_change(event)
    changed_attributes = event.data[:changed_attributes] || {}
    changed_attributes[:assignee_id] || changed_attributes['assignee_id']
  end

  def notification_visible?(event)
    return true unless Virti::Acl.enabled?

    notification = event.data[:notification]
    return true if notification.blank?

    Virti::Acl::NotificationPolicy.new(
      user: notification.user,
      account: notification.account,
      notification: notification
    ).show?
  end
end
