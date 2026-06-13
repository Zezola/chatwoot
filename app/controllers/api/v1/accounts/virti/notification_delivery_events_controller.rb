class Api::V1::Accounts::Virti::NotificationDeliveryEventsController < Api::V1::Accounts::BaseController
  before_action :ensure_administrator!

  def index
    events = filtered_events
    total = events.count
    page_events = events.includes(:user).order(occurred_at: :desc, id: :desc).offset(offset).limit(limit)

    render json: {
      total: total,
      offset: offset,
      limit: limit,
      summary: summary_for(events),
      subscriptions: subscriptions_payload,
      events: page_events.map { |event| serialize_event(event) }
    }
  end

  private

  def ensure_administrator!
    render_unauthorized('You are not authorized to do this action') unless Current.account_user&.administrator?
  end

  def filtered_events
    events = Virti::NotificationDeliveryEvent.where(account: Current.account)
    events = events.where(user_id: params[:agent_id]) if params[:agent_id].present?
    events = events.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?
    events = events.where(conversation_display_id: params[:conversation_display_id]) if params[:conversation_display_id].present?
    events = events.where(notification_id: params[:notification_id]) if params[:notification_id].present?
    events = events.where(notification_subscription_id: params[:subscription_id]) if params[:subscription_id].present?
    events = events.where(event_type: params[:event_type]) if params[:event_type].present?
    events = events.where(status: params[:status]) if params[:status].present?
    events = events.where(channel: params[:channel]) if params[:channel].present?
    events = events.where(provider: params[:provider]) if params[:provider].present?
    events = events.where(device_type: params[:device_type]) if params[:device_type].present?
    events = events.where(platform: params[:platform]) if params[:platform].present?
    start_time = parsed_time(params[:inicio]) if params[:inicio].present?
    end_time = parsed_time(params[:fim]) if params[:fim].present?
    events = events.where('occurred_at >= ?', start_time) if start_time.present?
    events = events.where('occurred_at <= ?', end_time) if end_time.present?
    events
  end

  def summary_for(events)
    {
      byEventType: events.group(:event_type).count,
      byStatus: events.group(:status).count,
      byChannel: events.group(:channel).count,
      byDeviceType: events.group(:device_type).count
    }
  end

  def subscriptions_payload
    return [] if params[:agent_id].blank?

    user = Current.account.users.find_by(id: params[:agent_id])
    return [] if user.blank?

    user.notification_subscriptions.order(:id).map do |subscription|
      attrs = subscription.subscription_attributes || {}
      {
        id: subscription.id,
        type: subscription.subscription_type,
        identifier: subscription.identifier,
        deviceType: attrs['device_type'],
        platform: attrs['platform'],
        userAgent: attrs['user_agent'],
        createdAt: subscription.created_at,
        updatedAt: subscription.updated_at
      }
    end
  end

  def serialize_event(event)
    {
      id: event.id,
      agentId: event.user_id,
      agentName: event.user&.name,
      agentEmail: event.user&.email,
      notificationId: event.notification_id,
      subscriptionId: event.notification_subscription_id,
      conversationId: event.conversation_id,
      conversationDisplayId: event.conversation_display_id,
      eventType: event.event_type,
      channel: event.channel,
      provider: event.provider,
      status: event.status,
      deviceType: event.device_type,
      platform: event.platform,
      userAgent: event.user_agent,
      errorMessage: event.error_message,
      metadata: include_metadata? ? event.metadata : nil,
      occurredAt: event.occurred_at,
      createdAt: event.created_at
    }
  end

  def include_metadata?
    ActiveModel::Type::Boolean.new.cast(params[:mostrar_metadata])
  end

  def offset
    [params[:offset].to_i, 0].max
  end

  def limit
    [[(params[:limite].presence || 50).to_i, 1].max, 100].min
  end

  def parsed_time(value)
    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
