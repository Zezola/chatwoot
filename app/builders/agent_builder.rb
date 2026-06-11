# The AgentBuilder class is responsible for creating a new agent.
# It initializes with necessary attributes and provides a perform method
# to create a user and account user in a transaction.
class AgentBuilder
  VIRTI_DEFAULT_LOCALE = 'pt_BR'.freeze

  # Initializes an AgentBuilder with necessary attributes.
  # @param email [String] the email of the user.
  # @param name [String] the name of the user.
  # @param role [String] the role of the user, defaults to 'agent' if not provided.
  # @param inviter [User] the user who is inviting the agent (Current.user in most cases).
  # @param availability [String] the availability status of the user, defaults to 'offline' if not provided.
  # @param auto_offline [Boolean] the auto offline status of the user.
  pattr_initialize [:email, { name: '' }, :inviter, :account, { role: :agent }, { availability: :offline }, { auto_offline: false }]

  # Creates a user and account user in a transaction.
  # @return [User] the created user.
  def perform
    ActiveRecord::Base.transaction do
      @user = find_or_create_user
      create_account_user
    end
    @user
  end

  private

  # Finds a user by email or creates a new one with a temporary password.
  # @return [User] the found or created user.
  def find_or_create_user
    user = User.from_email(email)
    return ensure_user_locale(user) if user

    @name = email.split('@').first if @name.blank?
    temp_password = "1!aA#{SecureRandom.alphanumeric(12)}"
    User.create!(email: email, name: @name, password: temp_password, password_confirmation: temp_password, ui_settings: locale_settings)
  end

  def ensure_user_locale(user)
    user.update!(ui_settings: locale_settings(user)) if user.ui_settings&.dig('locale') != user_locale
    user
  end

  def locale_settings(user = nil)
    (user&.ui_settings || {}).merge('locale' => user_locale)
  end

  def user_locale
    VIRTI_DEFAULT_LOCALE
  end

  # Checks if the user needs confirmation.
  # @return [Boolean] true if the user is persisted and not confirmed, false otherwise.
  def user_needs_confirmation?
    @user.persisted? && !@user.confirmed?
  end

  # Creates an account user linking the user to the current account.
  def create_account_user
    AccountUser.create!({
      account_id: account.id,
      user_id: @user.id,
      inviter_id: inviter.id
    }.merge({
      role: role,
      availability: availability,
      auto_offline: auto_offline
    }.compact))
  end
end

AgentBuilder.prepend_mod_with('AgentBuilder')
