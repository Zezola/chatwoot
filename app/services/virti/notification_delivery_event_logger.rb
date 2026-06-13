class Virti::NotificationDeliveryEventLogger
  DEFAULT_DEVICE_TYPE = 'unknown'.freeze
  DEFAULT_PLATFORM = 'unknown'.freeze

  def self.record(notification:, subscription:, event_type:, channel:, provider:, status:, delivery_token:, metadata: {}, error_message: nil)
    new(
      notification: notification,
      subscription: subscription,
      event_type: event_type,
      channel: channel,
      provider: provider,
      status: status,
      delivery_token: delivery_token,
      metadata: metadata,
      error_message: error_message
    ).record
  end

  def self.record_token_event(delivery_token:, event_type:, status:, metadata: {})
    source_event = Virti::NotificationDeliveryEvent.where(delivery_token: delivery_token).order(:created_at).first
    return if source_event.blank?

    Virti::NotificationDeliveryEvent.create!(
      account_id: source_event.account_id,
      user_id: source_event.user_id,
      notification_id: source_event.notification_id,
      notification_subscription_id: source_event.notification_subscription_id,
      conversation_id: source_event.conversation_id,
      conversation_display_id: source_event.conversation_display_id,
      delivery_token: delivery_token,
      event_type: event_type,
      channel: source_event.channel,
      provider: source_event.provider,
      status: status,
      device_type: source_event.device_type,
      platform: source_event.platform,
      user_agent: source_event.user_agent,
      metadata: source_event.metadata.merge(metadata || {}),
      occurred_at: Time.current
    )
  end

  def initialize(notification:, subscription:, event_type:, channel:, provider:, status:, delivery_token:, metadata:, error_message:)
    @notification = notification
    @subscription = subscription
    @event_type = event_type
    @channel = channel
    @provider = provider
    @status = status
    @delivery_token = delivery_token
    @metadata = metadata || {}
    @error_message = error_message
  end

  def record
    Virti::NotificationDeliveryEvent.create!(
      account_id: notification.account_id,
      user_id: notification.user_id,
      notification_id: notification.id,
      notification_subscription_id: subscription.id,
      conversation_id: conversation&.id,
      conversation_display_id: conversation&.display_id,
      delivery_token: delivery_token,
      event_type: event_type,
      channel: channel,
      provider: provider,
      status: status,
      device_type: device_type,
      platform: platform,
      user_agent: subscription_attributes['user_agent'],
      error_message: error_message,
      metadata: metadata,
      occurred_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.warn("Virti push telemetry failed: #{e.class.name}: #{e.message}")
    nil
  end

  private

  attr_reader :notification, :subscription, :event_type, :channel, :provider, :status, :delivery_token, :metadata, :error_message

  def conversation
    @conversation ||= notification.conversation
  end

  def subscription_attributes
    @subscription_attributes ||= subscription.subscription_attributes || {}
  end

  def device_type
    subscription_attributes['device_type'].presence || (subscription.fcm? ? 'mobile' : DEFAULT_DEVICE_TYPE)
  end

  def platform
    subscription_attributes['platform'].presence || DEFAULT_PLATFORM
  end
end
