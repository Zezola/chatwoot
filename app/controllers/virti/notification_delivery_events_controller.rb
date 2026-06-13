class Virti::NotificationDeliveryEventsController < ActionController::Base
  def received
    Virti::NotificationDeliveryEventLogger.record_token_event(
      delivery_token: params[:delivery_token], event_type: 'browser_received', status: 'success'
    )
    head :ok
  end

  def clicked
    source_event = Virti::NotificationDeliveryEvent.where(delivery_token: params[:delivery_token]).order(:created_at).first
    Virti::NotificationDeliveryEventLogger.record_token_event(
      delivery_token: params[:delivery_token], event_type: 'browser_clicked', status: 'success'
    )

    return head :ok if params[:track_only].present?

    redirect_to(source_event&.metadata&.dig('target_url').presence || ENV.fetch('FRONTEND_URL', '/'), allow_other_host: true)
  end
end
