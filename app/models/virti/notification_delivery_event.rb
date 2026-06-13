class Virti::NotificationDeliveryEvent < ApplicationRecord
  self.table_name = 'virti_notification_delivery_events'

  belongs_to :account
  belongs_to :user
  belongs_to :notification, optional: true
  belongs_to :notification_subscription, optional: true
  belongs_to :conversation, optional: true

  validates :event_type, :channel, :provider, :status, :occurred_at, presence: true
end
