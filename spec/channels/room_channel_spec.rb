require 'rails_helper'

RSpec.describe RoomChannel do
  let!(:contact_inbox) { create(:contact_inbox) }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }

  before do
    stub_connection
  end

  it 'subscribes to a stream when pubsub_token is provided' do
    subscribe(pubsub_token: contact_inbox.pubsub_token)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(contact_inbox.pubsub_token)
  end

  it 'subscribes to a stream when pubsub_token is provided for user' do
    subscribe(user_id: user.id, pubsub_token: user.pubsub_token, account_id: account.id)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(user.pubsub_token)
    expect(subscription).to have_stream_for("account_#{account.id}")
  end

  it 'broadcasts only online contact ids authorized by Virti ACL in presence.update' do
    presence = prepare_presence_acl_scenario
    expected_contacts = { presence[:visible_contact].id.to_s => 'online' }

    log_action_cable_characterization(
      'presence.update',
      user.pubsub_token,
      "contacts=#{expected_contacts.keys.inspect} hidden_contact_id=#{presence[:hidden_contact].id} filtered"
    )

    expect(ActionCable.server).to receive(:broadcast).with(
      user.pubsub_token,
      {
        event: 'presence.update',
        data: { account_id: account.id, users: presence[:users], contacts: expected_contacts }
      }
    )

    subscribe(user_id: user.id, pubsub_token: user.pubsub_token, account_id: account.id)
  end

  it 'keeps all online contact ids in presence.update when Virti ACL is disabled' do
    presence = prepare_presence_acl_scenario

    expect(ActionCable.server).to receive(:broadcast).with(
      user.pubsub_token,
      {
        event: 'presence.update',
        data: { account_id: account.id, users: presence[:users], contacts: presence[:contacts] }
      }
    )

    with_modified_env VIRTI_ACL_ENABLED: 'false' do
      subscribe(user_id: user.id, pubsub_token: user.pubsub_token, account_id: account.id)
    end
  end

  def prepare_presence_acl_scenario
    inbox = create(:inbox, account: account)
    other_agent = create(:user, account: account, role: :agent)
    create(:inbox_member, inbox: inbox, user: user)
    create(:inbox_member, inbox: inbox, user: other_agent)
    visible_contact, hidden_contact = create_presence_contacts(inbox, other_agent)
    restrict_conversation_acl(user)

    stub_presence(visible_contact, hidden_contact)
  end

  def create_presence_contacts(inbox, other_agent)
    visible_contact = create(:contact, account: account)
    hidden_contact = create(:contact, account: account)
    create(:conversation, account: account, inbox: inbox, contact: visible_contact, assignee: user)
    create(:conversation, account: account, inbox: inbox, contact: hidden_contact, assignee: other_agent)

    [visible_contact, hidden_contact]
  end

  def stub_presence(visible_contact, hidden_contact)
    contacts_presence = { visible_contact.id.to_s => 'online', hidden_contact.id.to_s => 'online' }
    users_presence = { user.id.to_s => 'online' }
    allow(OnlineStatusTracker).to receive(:update_presence)
    allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id).and_return(users_presence)
    allow(OnlineStatusTracker).to receive(:get_available_contacts).with(account.id).and_return(contacts_presence)

    { contacts: contacts_presence, hidden_contact: hidden_contact, users: users_presence, visible_contact: visible_contact }
  end

  def restrict_conversation_acl(user)
    model = create(
      :virti_acl_model,
      account: account,
      permissions: { 'pode_ver_aba_de_todas_conversas' => false, 'pode_ver_aba_de_nao_atribuidas' => false }
    )
    create(:virti_acl_user_model, account: account, user: user, model: model)
  end

  def log_action_cable_characterization(event_name, token, details)
    Rails.logger.info("[Virti ACL characterization] #{event_name} ActionCable token=#{token.inspect} #{details}")
  end
end
