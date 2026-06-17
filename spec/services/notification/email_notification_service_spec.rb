require 'rails_helper'

describe Notification::EmailNotificationService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, confirmed_at: Time.current) }
  let(:conversation) { create(:conversation, account: account) }
  let(:notification) { create(:notification, notification_type: :conversation_creation, user: agent, account: account, primary_actor: conversation) }
  let(:mailer) { double }
  let(:mailer_action) { double }

  before do
    # Setup notification settings for the agent
    notification_setting = agent.notification_settings.find_by(account_id: account.id)
    notification_setting.selected_email_flags = [:email_conversation_creation]
    notification_setting.save!
  end

  describe '#perform' do
    context 'when notification is read' do
      before do
        notification.update!(read_at: Time.current)
      end

      it 'does not send email' do
        expect(AgentNotifications::ConversationNotificationsMailer).not_to receive(:with)
        described_class.new(notification: notification).perform
      end
    end

    context 'when agent is not confirmed' do
      before do
        agent.update!(confirmed_at: nil)
      end

      it 'does not send email' do
        expect(AgentNotifications::ConversationNotificationsMailer).not_to receive(:with)
        described_class.new(notification: notification).perform
      end
    end

    context 'when agent is confirmed' do
      before do
        allow(AgentNotifications::ConversationNotificationsMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:public_send).and_return(mailer_action)
        allow(mailer_action).to receive(:deliver_later)
      end

      it 'sends email' do
        described_class.new(notification: notification).perform
        expect(mailer).to have_received(:public_send).with(
          'conversation_creation',
          conversation,
          agent,
          nil
        )
      end
    end

    context 'when Virti ACL denies access to the conversation' do
      before do
        other_agent = create(:user, account: account, role: :agent)
        create(:inbox_member, inbox: conversation.inbox, user: other_agent)
        conversation.update!(assignee: other_agent)
        restrict_conversation_acl(agent)
      end

      it 'does not send email' do
        expect(AgentNotifications::ConversationNotificationsMailer).not_to receive(:with)
        described_class.new(notification: notification).perform
      end
    end

    context 'when user is not subscribed to notification type' do
      before do
        notification_setting = agent.notification_settings.find_by(account_id: account.id)
        notification_setting.selected_email_flags = []
        notification_setting.save!
      end

      it 'does not send email' do
        expect(AgentNotifications::ConversationNotificationsMailer).not_to receive(:with)
        described_class.new(notification: notification).perform
      end
    end
  end

  def restrict_conversation_acl(user)
    model = create(
      :virti_acl_model,
      account: account,
      permissions: { 'pode_ver_aba_de_todas_conversas' => false, 'pode_ver_aba_de_nao_atribuidas' => false }
    )
    create(:virti_acl_user_model, account: account, user: user, model: model)
  end
end
