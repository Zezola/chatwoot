require 'rails_helper'

RSpec.describe ActionCableBroadcastJob do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:allowed_agent) { create(:user, account: account, role: :agent) }
  let(:blocked_agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: allowed_agent) }
  let(:contact_token) { conversation.contact_inbox.pubsub_token }
  let(:server) { ActionCable.server }

  before do
    create(:inbox_member, inbox: inbox, user: allowed_agent)
    create(:inbox_member, inbox: inbox, user: blocked_agent)
    restrict_conversation_acl(allowed_agent, blocked_agent)
    allow(server).to receive(:broadcast)
  end

  it 'does not send message.created to users blocked by Virti ACL' do
    message = create(:message, account: account, inbox: inbox, conversation: conversation)
    payload = message.push_event_data.merge(account_id: account.id)

    perform_job([allowed_agent.pubsub_token, blocked_agent.pubsub_token, contact_token], 'message.created', payload)

    expect_broadcast_to(allowed_agent.pubsub_token, 'message.created', payload)
    expect_broadcast_to(contact_token, 'message.created', payload)
    expect_no_broadcast_to(blocked_agent.pubsub_token)
  end

  it 'does not send conversation.updated to users blocked by Virti ACL' do
    payload = conversation.push_event_data.merge(account_id: account.id)

    perform_job([allowed_agent.pubsub_token, blocked_agent.pubsub_token, contact_token], 'conversation.updated', payload)

    expect_broadcast_to(allowed_agent.pubsub_token, 'conversation.updated', conversation_payload_matcher)
    expect_broadcast_to(contact_token, 'conversation.updated', conversation_payload_matcher)
    expect_no_broadcast_to(blocked_agent.pubsub_token)
  end

  it 'does not send conversation.status_changed to users blocked by Virti ACL' do
    payload = conversation.push_event_data.merge(account_id: account.id)

    perform_job([allowed_agent.pubsub_token, blocked_agent.pubsub_token, contact_token], 'conversation.status_changed', payload)

    expect_broadcast_to(allowed_agent.pubsub_token, 'conversation.status_changed', conversation_payload_matcher)
    expect_broadcast_to(contact_token, 'conversation.status_changed', conversation_payload_matcher)
    expect_no_broadcast_to(blocked_agent.pubsub_token)
  end

  it 'does not send typing events to users blocked by Virti ACL' do
    payload = {
      conversation: conversation.push_event_data,
      user: allowed_agent.push_event_data,
      account_id: account.id,
      is_private: false
    }

    perform_job([allowed_agent.pubsub_token, blocked_agent.pubsub_token, contact_token], 'conversation.typing_on', payload)

    expect_broadcast_to(allowed_agent.pubsub_token, 'conversation.typing_on', payload)
    expect_broadcast_to(contact_token, 'conversation.typing_on', payload)
    expect_no_broadcast_to(blocked_agent.pubsub_token)
  end

  it 'does not send contact events to users blocked by Virti ACL' do
    payload = conversation.contact.push_event_data.merge(account_id: account.id)
    event_names = %w[contact.created contact.updated contact.merged contact.deleted]
    tokens = [allowed_agent.pubsub_token, blocked_agent.pubsub_token, "account_#{account.id}"]

    event_names.each do |event_name|
      log_action_cable_characterization(event_name, tokens, payload)
      perform_job(tokens, event_name, payload)

      expect_broadcast_to(allowed_agent.pubsub_token, event_name, payload)
      expect_no_broadcast_to(blocked_agent.pubsub_token)
      expect_no_broadcast_to("account_#{account.id}")
    end
  end

  it 'keeps contact event behavior unchanged when Virti ACL is disabled' do
    payload = conversation.contact.push_event_data.merge(account_id: account.id)

    with_modified_env VIRTI_ACL_ENABLED: 'false' do
      perform_job([blocked_agent.pubsub_token], 'contact.updated', payload)
    end

    expect_broadcast_to(blocked_agent.pubsub_token, 'contact.updated', payload)
  end

  it 'keeps original behavior when Virti ACL is disabled' do
    message = create(:message, account: account, inbox: inbox, conversation: conversation)
    payload = message.push_event_data.merge(account_id: account.id)

    with_modified_env VIRTI_ACL_ENABLED: 'false' do
      perform_job([blocked_agent.pubsub_token], 'message.created', payload)
    end

    expect_broadcast_to(blocked_agent.pubsub_token, 'message.created', payload)
  end

  it 'classifies all conversation and message ActionCable listener events for Virti ACL filtering' do
    expected_event_names = [
      Events::Types::MESSAGE_CREATED,
      Events::Types::MESSAGE_UPDATED,
      Events::Types::FIRST_REPLY_CREATED,
      Events::Types::CONVERSATION_CREATED,
      Events::Types::CONVERSATION_UPDATED,
      Events::Types::CONVERSATION_READ,
      Events::Types::CONVERSATION_STATUS_CHANGED,
      Events::Types::CONVERSATION_TYPING_ON,
      Events::Types::CONVERSATION_TYPING_OFF,
      Events::Types::ASSIGNEE_CHANGED,
      Events::Types::TEAM_CHANGED,
      Events::Types::CONVERSATION_CONTACT_CHANGED,
      Events::Types::CONVERSATION_MENTIONED
    ]

    expect(Virti::Acl::Patches::ActionCableBroadcastJobPatch::CONVERSATION_EVENT_NAMES).to include(*expected_event_names)
  end

  def perform_job(members, event_name, payload)
    described_class.new.perform(members, event_name, payload)
  end

  def restrict_conversation_acl(*users)
    model = create(
      :virti_acl_model,
      account: account,
      permissions: { 'pode_ver_aba_de_todas_conversas' => false, 'pode_ver_aba_de_nao_atribuidas' => false }
    )

    users.each do |user|
      create(:virti_acl_user_model, account: account, user: user, model: model)
    end
  end

  def conversation_payload_matcher
    hash_including(account_id: account.id, id: conversation.display_id)
  end

  def expect_broadcast_to(token, event_name, data)
    expect(server).to have_received(:broadcast).with(token, { event: event_name, data: data })
  end

  def expect_no_broadcast_to(token)
    expect(server).not_to have_received(:broadcast).with(token, anything)
  end

  def log_action_cable_characterization(event_name, tokens, payload)
    Rails.logger.info(
      "[Virti ACL characterization] #{event_name} ActionCable tokens=#{tokens.inspect} payload_keys=#{payload.keys.inspect}"
    )
  end
end
