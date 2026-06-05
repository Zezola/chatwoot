class Api::V1::Accounts::Virti::Acl::UserModelsController < Api::V1::Accounts::BaseController
  before_action :ensure_administrator!
  before_action :fetch_user

  def show
    user_model = Virti::Acl::UserModel.find_by(account: Current.account, user: @user)

    render json: serialize_user_model(user_model)
  end

  def update
    model = Current.account.virti_acl_models.find(params.require(:model_id))
    user_model = Virti::Acl::UserModel.find_or_initialize_by(account: Current.account, user: @user)
    user_model.assign_attributes(model: model, updated_by: current_user)
    user_model.created_by ||= current_user
    user_model.save!

    render json: serialize_user_model(user_model)
  end

  def destroy
    user_model = Virti::Acl::UserModel.find_by(account: Current.account, user: @user)
    user_model&.destroy!

    head :ok
  end

  private

  def ensure_administrator!
    render_unauthorized('You are not authorized to do this action') unless Current.account_user&.administrator?
  end

  def fetch_user
    @user = Current.account.users.find(params[:user_id])
  end

  def serialize_user_model(user_model)
    result = Virti::Acl::PermissionsResolver.new(user: @user, account: Current.account).resolve
    return { userId: @user.id, aclSource: result.acl_source, model: nil, permissions: result.permissions } if user_model.blank?

    {
      userId: @user.id,
      aclSource: result.acl_source,
      model: {
        id: user_model.model.id,
        name: user_model.model.name,
        description: user_model.model.description
      },
      permissions: result.permissions
    }
  end
end
