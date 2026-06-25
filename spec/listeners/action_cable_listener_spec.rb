require 'rails_helper'
describe ActionCableListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    Current.user = nil
    Current.account = nil
  end

  describe '#message_created' do
    let(:event_name) { :'message.created' }
    let!(:message) do
      create(:message, message_type: 'outgoing',
                       account: account, inbox: inbox, conversation: conversation)
    end
    let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }

    it 'sends message to account admins, inbox agents and the contact' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(
          agent.pubsub_token, admin.pubsub_token, conversation.contact_inbox.pubsub_token
        ),
        'message.created',
        message.push_event_data.merge(account_id: account.id)
      )
      listener.message_created(event)
    end

    it 'sends message to all hmac verified contact inboxes' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      conversation.contact_inbox.update(hmac_verified: true)
      # creating a non verified contact inbox to ensure the events are not sent to it
      create(:contact_inbox, contact: conversation.contact, inbox: inbox)
      verified_contact_inbox = create(:contact_inbox, contact: conversation.contact, inbox: inbox, hmac_verified: true)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(
          agent.pubsub_token, admin.pubsub_token, conversation.contact_inbox.pubsub_token, verified_contact_inbox.pubsub_token
        ),
        'message.created',
        message.push_event_data.merge(account_id: account.id)
      )
      listener.message_created(event)
    end
  end

  describe '#typing_on' do
    let(:event_name) { :'conversation.typing_on' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: agent, is_private: false) }

    it 'sends message to account admins, inbox agents and the contact' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(
          admin.pubsub_token, conversation.contact_inbox.pubsub_token
        ),
        'conversation.typing_on', { conversation: conversation.push_event_data,
                                    user: agent.push_event_data,
                                    account_id: account.id,
                                    is_private: false }
      )
      listener.conversation_typing_on(event)
    end
  end

  describe '#typing_on with contact' do
    let(:event_name) { :'conversation.typing_on' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: conversation.contact, is_private: false) }

    it 'sends message to account admins, inbox agents and the contact' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(
          admin.pubsub_token, agent.pubsub_token
        ),
        'conversation.typing_on', { conversation: conversation.push_event_data,
                                    user: conversation.contact.push_event_data,
                                    account_id: account.id,
                                    is_private: false }
      )
      listener.conversation_typing_on(event)
    end
  end

  describe '#typing_on with agent bot' do
    let(:event_name) { :'conversation.typing_on' }
    let!(:agent_bot) { create(:agent_bot, account: account) }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: agent_bot, is_private: false) }

    it 'sends message to account admins, inbox agents and the contact' do
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(
          admin.pubsub_token, agent.pubsub_token, conversation.contact_inbox.pubsub_token
        ),
        'conversation.typing_on', { conversation: conversation.push_event_data,
                                    user: agent_bot.push_event_data,
                                    account_id: account.id,
                                    is_private: false }
      )
      listener.conversation_typing_on(event)
    end
  end

  describe '#typing_off' do
    let(:event_name) { :'conversation.typing_off' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: agent, is_private: false) }

    it 'sends message to account admins, inbox agents and the contact' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(
          admin.pubsub_token, conversation.contact_inbox.pubsub_token
        ),
        'conversation.typing_off', { conversation: conversation.push_event_data,
                                     user: agent.push_event_data,
                                     account_id: account.id,
                                     is_private: false }
      )
      listener.conversation_typing_off(event)
    end
  end

  describe '#contact_deleted' do
    let(:event_name) { :'contact.deleted' }
    let(:contact) { conversation.contact }
    let!(:blocked_agent) { create(:user, account: account, role: :agent) }
    let(:contact_data) { contact.push_event_data.merge(account_id: contact.account_id) }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, contact_data: contact_data) }

    before do
      restrict_conversation_acl(agent, admin, blocked_agent)
    end

    it 'broadcasts contact.deleted only to users authorized by Virti ACL' do
      log_action_cable_characterization('contact.deleted', [agent.pubsub_token], contact_data)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'contact.deleted',
        contact_data
      )
      listener.contact_deleted(event)
    end
  end

  describe 'contact events' do
    let(:contact) { conversation.contact }
    let!(:blocked_agent) { create(:user, account: account, role: :agent) }

    before do
      restrict_conversation_acl(agent, admin, blocked_agent)
    end

    it 'broadcasts contact.created only to users authorized by Virti ACL' do
      event = Events::Base.new(:'contact.created', Time.zone.now, contact: contact)
      log_action_cable_characterization('contact.created', [agent.pubsub_token], contact.push_event_data)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'contact.created',
        contact.push_event_data.merge(account_id: account.id)
      )

      listener.contact_created(event)
    end

    it 'broadcasts contact.updated only to users authorized by Virti ACL' do
      event = Events::Base.new(:'contact.updated', Time.zone.now, contact: contact)
      log_action_cable_characterization('contact.updated', [agent.pubsub_token], contact.push_event_data)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'contact.updated',
        contact.push_event_data.merge(account_id: account.id)
      )

      listener.contact_updated(event)
    end

    it 'broadcasts contact.merged only to users authorized by Virti ACL' do
      event = Events::Base.new(
        :'contact.merged',
        Time.zone.now,
        contact: contact,
        tokens: [contact.contact_inboxes.filter_map(&:pubsub_token)]
      )
      log_action_cable_characterization('contact.merged', [agent.pubsub_token], contact.push_event_data)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'contact.merged',
        contact.push_event_data.merge(account_id: account.id)
      )

      listener.contact_merged(event)
    end

    it 'keeps contact.updated account-wide when Virti ACL is disabled' do
      event = Events::Base.new(:'contact.updated', Time.zone.now, contact: contact)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        ["account_#{account.id}"],
        'contact.updated',
        contact.push_event_data.merge(account_id: account.id)
      )

      with_modified_env VIRTI_ACL_ENABLED: 'false' do
        listener.contact_updated(event)
      end
    end
  end

  describe '#notification_deleted' do
    let(:event_name) { :'notification.deleted' }
    let!(:notification) { create(:notification, account: account, user: agent) }
    let(:notification_data) do
      {
        id: notification.id,
        user_id: agent.id,
        account_id: account.id
      }
    end
    let!(:event) { Events::Base.new(event_name, Time.zone.now, notification_data: notification_data) }

    it 'sends message to account admins, inbox agents' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'notification.deleted',
        {
          account_id: notification.account_id,
          notification: {
            id: notification.id
          },
          unread_count: 1,
          count: 1
        }
      )

      listener.notification_deleted(event)
    end
  end

  describe '#notification_created' do
    let(:event_name) { :'notification.created' }
    let!(:notification) { create(:notification, account: account, user: agent, primary_actor: conversation) }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, notification: notification) }

    it 'sends notification to the notification user' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'notification.created',
        {
          account_id: notification.account_id,
          notification: notification.push_event_data,
          unread_count: 1,
          count: 1
        }
      )

      listener.notification_created(event)
    end

    it 'does not send notification when Virti ACL denies access to the conversation' do
      other_agent = create(:user, account: account, role: :agent)
      create(:inbox_member, inbox: inbox, user: other_agent)
      conversation.update!(assignee: other_agent)
      restrict_conversation_acl(agent)

      expect(ActionCableBroadcastJob).not_to receive(:perform_later)

      listener.notification_created(event)
    end
  end

  describe '#notification_updated' do
    let(:event_name) { :'notification.updated' }
    let!(:notification) { create(:notification, account: account, user: agent, primary_actor: conversation) }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, notification: notification) }

    it 'sends notification to account admins, inbox agents' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'notification.updated',
        {
          account_id: notification.account_id,
          notification: notification.push_event_data,
          unread_count: 1,
          count: 1
        }
      )

      listener.notification_updated(event)
    end

    it 'does not send notification when Virti ACL denies access to the conversation' do
      other_agent = create(:user, account: account, role: :agent)
      create(:inbox_member, inbox: inbox, user: other_agent)
      conversation.update!(assignee: other_agent)
      restrict_conversation_acl(agent)

      expect(ActionCableBroadcastJob).not_to receive(:perform_later)

      listener.notification_updated(event)
    end
  end

  describe '#conversation_updated' do
    let(:event_name) { :'conversation.updated' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: agent, is_private: false) }

    before do
      conversation.add_labels(['support'])
    end

    it 'sends update to inbox members' do
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token, admin.pubsub_token, conversation.contact_inbox.pubsub_token],
        'conversation.updated',
        conversation.push_event_data.merge(account_id: account.id)
      )
      listener.conversation_updated(event)
    end

    it 'broadcast event with label data' do
      expect(conversation.reload.push_event_data[:labels]).to eq(conversation.labels.pluck(:name))

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token, admin.pubsub_token, conversation.contact_inbox.pubsub_token],
        'conversation.updated',
        conversation.push_event_data.merge(account_id: account.id)
      )
      listener.conversation_updated(event)
    end
  end

  def restrict_conversation_acl(*users)
    model = create(
      :virti_acl_model,
      account: account,
      permissions: { 'pode_ver_aba_de_todas_conversas' => false, 'pode_ver_aba_de_nao_atribuidas' => false }
    )
    users.each { |user| create(:virti_acl_user_model, account: account, user: user, model: model) }
  end

  def log_action_cable_characterization(event_name, tokens, payload)
    Rails.logger.info(
      "[Virti ACL characterization] #{event_name} ActionCable tokens=#{tokens.inspect} payload_keys=#{payload.keys.inspect}"
    )
  end
end
