class Api::V1::Accounts::Virti::Acl::ModelsController < Api::V1::Accounts::BaseController
  rescue_from Virti::Acl::PermissionNormalizer::InvalidPermissionsError, with: :render_invalid_permissions

  before_action :ensure_administrator!
  before_action :fetch_model, only: [:show, :update, :destroy]

  def index
    render json: Current.account.virti_acl_models.order(:name).map { |model| serialize_model(model) }
  end

  def show
    render json: serialize_model(@model)
  end

  def create
    model = Current.account.virti_acl_models.create!(model_params.merge(created_by: current_user, updated_by: current_user))

    render json: serialize_model(model), status: :created
  end

  def update
    @model.update!(model_params.merge(updated_by: current_user))

    render json: serialize_model(@model)
  end

  def destroy
    if @model.user_models.exists?
      return render json: { error: 'ACL model is in use' }, status: :conflict
    end

    @model.destroy!
    head :ok
  end

  private

  def ensure_administrator!
    render_unauthorized('You are not authorized to do this action') unless Current.account_user&.administrator?
  end

  def fetch_model
    @model = Current.account.virti_acl_models.find(params[:id])
  end

  def model_params
    permitted_params = params.require(:model).permit(:name, :description, permissions: {})
    attributes = permitted_params.to_h

    if permitted_params.key?(:permissions)
      attributes['permissions'] = Virti::Acl::PermissionNormalizer.perform(permitted_params[:permissions] || {}, strict: true, allow_empty: false)
    elsif action_name == 'create'
      raise Virti::Acl::PermissionNormalizer::InvalidPermissionsError.new(
        invalidKeys: [],
        invalidValues: [],
        empty: true
      )
    end

    attributes
  end

  def render_invalid_permissions(error)
    render json: { error: 'Invalid ACL permissions', details: error.errors }, status: :unprocessable_entity
  end

  def serialize_model(model)
    {
      id: model.id,
      accountId: model.account_id,
      name: model.name,
      description: model.description,
      permissions: model.normalized_permissions,
      usersCount: model.user_models.where(account: Current.account).count,
      createdAt: model.created_at,
      updatedAt: model.updated_at
    }
  end
end
