class AgentNotifications::ConversationNotificationsMailer < ApplicationMailer
  def conversation_creation(conversation, agent, _user)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = conversation
    @notification_contact_name = conversation_contact_name
    subject = "Nova conversa de #{conversation_contact_name} (##{@conversation.display_id})"
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: @agent.email, subject: subject) and return
  end

  def conversation_assignment(conversation, agent, _user)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = conversation
    @notification_contact_name = conversation_contact_name
    subject = "Nova conversa de #{conversation_contact_name} (##{@conversation.display_id})"
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: @agent.email, subject: subject) and return
  end

  def conversation_mention(conversation, agent, message)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = conversation
    @message = message
    @notification_actor_name = notification_actor_name(@message)
    subject = "#{notification_actor_name(@message)} mencionou você na conversa (##{@conversation.display_id})"
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: @agent.email, subject: subject) and return
  end

  def assigned_conversation_new_message(conversation, agent, message)
    return unless smtp_config_set_or_development?
    # Don't spam with email notifications if agent is online
    return if ::OnlineStatusTracker.get_presence(message.account_id, 'User', agent.id)

    @agent = agent
    @conversation = conversation
    @message = message
    @notification_actor_name = notification_actor_name(@message)
    subject = "#{notification_actor_name(@message)} (##{@conversation.display_id}) enviou uma nova mensagem"
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: @agent.email, subject: subject) and return
  end

  def participating_conversation_new_message(conversation, agent, message)
    return unless smtp_config_set_or_development?
    # Don't spam with email notifications if agent is online
    return if ::OnlineStatusTracker.get_presence(message.account_id, 'User', agent.id)

    @agent = agent
    @conversation = conversation
    @message = message
    @notification_actor_name = notification_actor_name(@message)
    subject = "#{notification_actor_name(@message)} (##{@conversation.display_id}) enviou uma nova mensagem"
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: @agent.email, subject: subject) and return
  end

  private

  def conversation_contact_name
    @conversation.contact&.name.presence || 'Contato'
  end

  def notification_actor_name(message)
    sender = message&.sender
    return conversation_contact_name if sender.is_a?(Contact)

    sender.try(:available_name).presence || sender.try(:name).presence || conversation_contact_name
  end

  def liquid_locals
    super.merge({
                  notification_actor_name: @notification_actor_name,
                  notification_contact_name: @notification_contact_name
                })
  end

  def liquid_droppables
    super.merge({
                  user: @agent,
                  conversation: @conversation,
                  inbox: @conversation.inbox,
                  message: @message
                })
  end
end

AgentNotifications::ConversationNotificationsMailer.prepend_mod_with('AgentNotifications::ConversationNotificationsMailer')
