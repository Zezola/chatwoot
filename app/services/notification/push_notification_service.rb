class Notification::PushNotificationService
  include Rails.application.routes.url_helpers

  pattr_initialize [:notification!]

  def perform
    return unless allowed_by_virti_acl?
    return unless user_subscribed_to_notification?

    notification_subscriptions.each do |subscription|
      send_browser_push(subscription)
      send_fcm_push(subscription)
      send_push_via_chatwoot_hub(subscription)
    end
  end

  private

  delegate :user, to: :notification
  delegate :notification_subscriptions, to: :user
  delegate :notification_settings, to: :user

  def allowed_by_virti_acl?
    Virti::Acl::NotificationPolicy.new(user: user, account: notification.account, notification: notification).show?
  end

  def user_subscribed_to_notification?
    notification_setting = notification_settings.find_by(account_id: notification.account.id)
    return false if notification_setting.blank?
    return true if notification_setting.mandatory_push_notification_type?(notification.notification_type)

    return true if notification_setting.public_send("push_#{notification.notification_type}?")

    false
  end

  def conversation
    @conversation ||= notification.conversation
  end

  def push_message
    delivery_token = SecureRandom.urlsafe_base64(24)
    {
      title: notification.push_message_title,
      tag: "#{notification.notification_type}_#{conversation.display_id}_#{notification.id}",
      url: push_url,
      receivedUrl: virti_notification_delivery_event_path(delivery_token, 'received'),
      clickUrl: virti_notification_delivery_event_path(delivery_token, 'clicked'),
      deliveryToken: delivery_token
    }
  end

  def virti_notification_delivery_event_path(delivery_token, action)
    "/virti/notification_delivery_events/#{delivery_token}/#{action}"
  end

  def push_url
    app_account_conversation_url(account_id: conversation.account_id, id: conversation.display_id)
  end

  def can_send_browser_push?(subscription)
    VapidService.public_key && subscription.browser_push?
  end

  def browser_push_payload(subscription, push_message)
    {
      message: JSON.generate(push_message),
      endpoint: subscription.subscription_attributes['endpoint'],
      p256dh: subscription.subscription_attributes['p256dh'],
      auth: subscription.subscription_attributes['auth'],
      vapid: {
        subject: push_url,
        public_key: VapidService.public_key,
        private_key: VapidService.private_key
      },
      ssl_timeout: 5,
      open_timeout: 5,
      read_timeout: 5
    }
  end

  def send_browser_push(subscription)
    return unless can_send_browser_push?(subscription)

    message = push_message
    record_push_event(subscription, 'send_attempted', 'browser_push', 'webpush', 'attempted', message)
    WebPush.payload_send(**browser_push_payload(subscription, message))
    record_push_event(subscription, 'send_accepted', 'browser_push', 'webpush', 'success', message)
    Rails.logger.info("Browser push sent to #{user.email} with title #{message[:title]}")
  rescue StandardError => e
    record_push_event(subscription, 'send_failed', 'browser_push', 'webpush', 'failure', message, error_message: e.message) if message.present?
    handle_browser_push_error(e, subscription)
  end

  def handle_browser_push_error(error, subscription)
    case error
    when WebPush::ExpiredSubscription, WebPush::InvalidSubscription, WebPush::Unauthorized
      Rails.logger.info "WebPush subscription expired: #{error.message}"
      subscription.destroy!
    when WebPush::TooManyRequests
      Rails.logger.warn "WebPush rate limited for #{user.email} on account #{notification.account.id}: #{error.message}"
    when Errno::ECONNRESET, Net::OpenTimeout, Net::ReadTimeout, Socket::ResolutionError
      Rails.logger.error "WebPush operation error: #{error.message}"
    else
      ChatwootExceptionTracker.new(error, account: notification.account).capture_exception
      true
    end
  end

  def send_fcm_push(subscription)
    return unless firebase_credentials_present?
    return unless subscription.fcm?

    fcm_service = Notification::FcmService.new(
      GlobalConfigService.load('FIREBASE_PROJECT_ID', nil), GlobalConfigService.load('FIREBASE_CREDENTIALS', nil)
    )
    fcm = fcm_service.fcm_client
    message = push_message
    record_push_event(subscription, 'send_attempted', 'fcm', 'firebase', 'attempted', message)
    response = fcm.send_v1(fcm_options(subscription))
    remove_subscription_if_error(subscription, response, message)
  rescue StandardError => e
    record_push_event(subscription, 'send_failed', 'fcm', 'firebase', 'failure', message, error_message: e.message) if message.present?
    raise
  end

  def send_push_via_chatwoot_hub(subscription)
    return if firebase_credentials_present?
    return unless chatwoot_hub_enabled?
    return unless subscription.fcm?

    message = push_message
    record_push_event(subscription, 'send_attempted', 'fcm', 'chatwoot_hub', 'attempted', message)
    ChatwootHub.send_push(fcm_options(subscription))
    record_push_event(subscription, 'send_accepted', 'fcm', 'chatwoot_hub', 'success', message)
  rescue StandardError => e
    record_push_event(subscription, 'send_failed', 'fcm', 'chatwoot_hub', 'failure', message, error_message: e.message) if message.present?
    raise
  end

  def firebase_credentials_present?
    GlobalConfigService.load('FIREBASE_PROJECT_ID', nil) && GlobalConfigService.load('FIREBASE_CREDENTIALS', nil)
  end

  def chatwoot_hub_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_PUSH_RELAY_SERVER', true))
  end

  def remove_subscription_if_error(subscription, response, message)
    if JSON.parse(response[:body])['results']&.first&.keys&.include?('error')
      record_push_event(subscription, 'send_failed', 'fcm', 'firebase', 'failure', message, error_message: response[:body])
      subscription.destroy!
    else
      record_push_event(subscription, 'send_accepted', 'fcm', 'firebase', 'success', message)
      Rails.logger.info("FCM push sent to #{user.email} with title #{message[:title]}")
    end
  end

  def fcm_options(subscription)
    {
      'token': subscription.subscription_attributes['push_token'],
      'data': fcm_data,
      'notification': fcm_notification,
      'android': fcm_android_options,
      'apns': fcm_apns_options,
      'fcm_options': {
        analytics_label: 'Label'
      }
    }
  end

  def record_push_event(subscription, event_type, channel, provider, status, message, error_message: nil)
    Virti::NotificationDeliveryEventLogger.record(
      notification: notification,
      subscription: subscription,
      event_type: event_type,
      channel: channel,
      provider: provider,
      status: status,
      delivery_token: message[:deliveryToken],
      error_message: error_message,
      metadata: {
        title: message[:title],
        target_url: push_url,
        tag: message[:tag]
      }
    )
  end

  def fcm_data
    {
      payload: {
        data: {
          notification: notification.fcm_push_data
        }
      }.to_json
    }
  end

  def fcm_notification
    {
      title: notification.push_message_title,
      body: notification.push_message_body
    }
  end

  def fcm_android_options
    {
      priority: 'high'
    }
  end

  def fcm_apns_options
    {
      payload: {
        aps: {
          sound: 'default',
          category: Time.zone.now.to_i.to_s
        }
      }
    }
  end
end
