# == Schema Information
#
# Table name: notification_settings
#
#  id          :bigint           not null, primary key
#  email_flags :integer          default(0), not null
#  push_flags  :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer
#  user_id     :integer
#
# Indexes
#
#  by_account_user  (account_id,user_id) UNIQUE
#

class NotificationSetting < ApplicationRecord
  # used for single column multi flags
  include FlagShihTzu

  MANDATORY_AGENT_PUSH_NOTIFICATION_TYPES = %w[
    conversation_assignment
    conversation_mention
    assigned_conversation_new_message
    participating_conversation_new_message
  ].freeze

  MANDATORY_AGENT_PUSH_NOTIFICATION_FLAGS = MANDATORY_AGENT_PUSH_NOTIFICATION_TYPES.map { |type| "push_#{type}" }.freeze

  belongs_to :account
  belongs_to :user

  DEFAULT_QUERY_SETTING = {
    flag_query_mode: :bit_operator,
    check_for_column: false
  }.freeze

  EMAIL_NOTIFICATION_FLAGS = ::Notification::NOTIFICATION_TYPES.transform_keys { |key| "email_#{key}".to_sym }.invert.freeze
  PUSH_NOTIFICATION_FLAGS = ::Notification::NOTIFICATION_TYPES.transform_keys { |key| "push_#{key}".to_sym }.invert.freeze

  has_flags EMAIL_NOTIFICATION_FLAGS.merge(column: 'email_flags').merge(DEFAULT_QUERY_SETTING)
  has_flags PUSH_NOTIFICATION_FLAGS.merge(column: 'push_flags').merge(DEFAULT_QUERY_SETTING)

  def mandatory_push_notification_type?(notification_type)
    mandatory_push_notification_flags.include?("push_#{notification_type}")
  end

  def with_mandatory_push_flags(flags)
    Array(flags).map(&:to_s) | mandatory_push_notification_flags
  end

  def selected_push_flags_with_mandatory
    with_mandatory_push_flags(selected_push_flags)
  end

  private

  def mandatory_push_notification_flags
    account_user&.agent? ? MANDATORY_AGENT_PUSH_NOTIFICATION_FLAGS : []
  end

  def account_user
    @account_user ||= AccountUser.find_by(account_id: account_id, user_id: user_id)
  end
end
