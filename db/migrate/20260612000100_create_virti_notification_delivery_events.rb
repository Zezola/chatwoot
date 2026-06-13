class CreateVirtiNotificationDeliveryEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :virti_notification_delivery_events do |t|
      t.bigint :account_id, null: false
      t.bigint :user_id, null: false
      t.bigint :notification_id
      t.bigint :notification_subscription_id
      t.bigint :conversation_id
      t.integer :conversation_display_id
      t.string :delivery_token
      t.string :event_type, null: false
      t.string :channel, null: false
      t.string :provider, null: false
      t.string :status, null: false
      t.string :device_type
      t.string :platform
      t.text :user_agent
      t.text :error_message
      t.jsonb :metadata, null: false, default: {}
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :virti_notification_delivery_events, :account_id
    add_index :virti_notification_delivery_events, :user_id
    add_index :virti_notification_delivery_events, :notification_id
    add_index :virti_notification_delivery_events, :notification_subscription_id, name: 'idx_virti_push_events_on_subscription_id'
    add_index :virti_notification_delivery_events, :conversation_id
    add_index :virti_notification_delivery_events, :conversation_display_id
    add_index :virti_notification_delivery_events, :delivery_token
    add_index :virti_notification_delivery_events, :event_type
    add_index :virti_notification_delivery_events, :occurred_at
    add_index :virti_notification_delivery_events, [:account_id, :user_id, :occurred_at], name: 'idx_virti_push_events_account_user_time'
  end
end
