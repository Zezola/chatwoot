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

  it 'keeps non-conversation events unchanged' do
    payload = { account_id: account.id, id: conversation.contact_id }

    perform_job([blocked_agent.pubsub_token], 'contact.updated', payload)

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
end
