class Api::V1::Accounts::Virti::Kanban::UserModelsController < Api::V1::Accounts::Virti::Kanban::BaseController
  before_action :ensure_administrator!
  before_action :fetch_user, only: [:show, :update, :destroy]

  def index
    user_models_by_user_id = Virti::Kanban::UserModel.includes(:model).where(account: Current.account).index_by(&:user_id)
    agents = Current.account.account_users.includes(:user).order(:user_id)

    render json: agents.map { |account_user| serialize_user_model_for_user(account_user.user, user_models_by_user_id[account_user.user_id]) }
  end

  def show
    user_model = Virti::Kanban::UserModel.find_by(account: Current.account, user: @user)

    render json: serialize_user_model_for_user(@user, user_model)
  end

  def update
    model = Current.account.virti_kanban_models.find(params.require(:model_id))
    user_model = Virti::Kanban::UserModel.find_or_initialize_by(account: Current.account, user: @user)
    user_model.assign_attributes(model: model, updated_by: current_user)
    user_model.created_by ||= current_user
    user_model.save!
    broadcast_kanban_user_updated(@user, model_id: model.id, action: 'user_model_updated')

    render json: serialize_user_model_for_user(@user, user_model)
  end

  def destroy
    user_model = Virti::Kanban::UserModel.find_by(account: Current.account, user: @user)
    model_id = user_model&.model_id
    user_model&.destroy!
    broadcast_kanban_user_updated(@user, model_id: model_id, action: 'user_model_removed') if model_id.present?

    head :ok
  end

  private

  def fetch_user
    @user = Current.account.users.find(params[:user_id])
  end

  def serialize_user_model_for_user(user, user_model)
    {
      userId: user.id,
      name: user.name,
      email: user.email,
      model: user_model.present? ? serialize_model_summary(user_model.model) : nil
    }
  end
end
