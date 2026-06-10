class Api::V1::Accounts::Virti::Kanban::BoardsController < Api::V1::Accounts::Virti::Kanban::BaseController
  before_action :ensure_administrator!, only: [:show_user]

  def show
    user_model = Virti::Kanban::UserModel.find_by(account: Current.account, user: current_user)

    render json: serialize_effective_kanban(current_user, user_model)
  end

  def show_user
    user = Current.account.users.find(params[:user_id])
    user_model = Virti::Kanban::UserModel.find_by(account: Current.account, user: user)

    render json: serialize_effective_kanban(user, user_model)
  end
end
