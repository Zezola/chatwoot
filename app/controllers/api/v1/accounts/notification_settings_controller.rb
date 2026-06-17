class Api::V1::Accounts::NotificationSettingsController < Api::V1::Accounts::BaseController
  before_action :set_user, :load_notification_setting

  def show; end

  def update
    update_flags
    @notification_setting.save!
    render action: 'show'
  end

  private

  def set_user
    @user = current_user
  end

  def load_notification_setting
    @notification_setting = @user.notification_settings.find_by(account_id: Current.account.id)
  end

  def notification_setting_params
    params.require(:notification_settings).permit(selected_email_flags: [], selected_push_flags: [])
  end

  def update_flags
    settings_params = notification_setting_params
    @notification_setting.selected_email_flags = settings_params[:selected_email_flags] if settings_params.key?(:selected_email_flags)

    return unless settings_params.key?(:selected_push_flags)

    @notification_setting.selected_push_flags = @notification_setting.with_mandatory_push_flags(settings_params[:selected_push_flags])
  end
end
