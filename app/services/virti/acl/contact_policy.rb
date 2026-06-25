class Virti::Acl::ContactPolicy
  def initialize(user:, account:, contact: nil, contact_id: nil)
    @user = user
    @account = account
    @contact = contact
    @contact_id = contact&.id || contact_id
  end

  def show?
    return true unless Virti::Acl.enabled?
    return true unless user.is_a?(User)
    return true if contact_id.blank?

    return existing_contact_visible? if contact.present?

    deleted_contact_visible?
  end

  private

  attr_reader :user, :account, :contact, :contact_id

  def existing_contact_visible?
    Virti::Acl::ContactScope.new(scope: account.contacts.where(id: contact_id), user: user, account: account).perform.exists?
  end

  def deleted_contact_visible?
    Virti::Acl::ConversationScope.new(
      scope: account.conversations.where(contact_id: contact_id),
      user: user,
      account: account
    ).perform.exists?
  end
end
