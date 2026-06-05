class Api::V1::Accounts::Virti::Acl::PermissionsController < Api::V1::Accounts::BaseController
  rescue_from Virti::Acl::PermissionNormalizer::InvalidPermissionsError, with: :render_invalid_permissions

  before_action :ensure_administrator!, only: [:show, :update]
  before_action :fetch_user, only: [:show, :update]

  def index
    render json: permission_response(current_user)
  end

  def show
    render json: permission_response(@user)
  end

  def update
    permission_record = Virti::Acl::UserPermission.active.find_or_initialize_by(IdUsuario: @user.id)
    permission_record.assign_attributes(
      Permissoes: normalized_permissions,
      CriadoEm: permission_record.CriadoEm || Time.current,
      AtualizadoEm: Time.current,
      DeletadoEm: nil
    )
    permission_record.save!

    render json: permission_response(@user)
  end

  private

  def ensure_administrator!
    render_unauthorized('You are not authorized to do this action') unless Current.account_user&.administrator?
  end

  def fetch_user
    @user = Current.account.users.find(params[:user_id])
  end

  def permission_response(user)
    result = Virti::Acl::PermissionsResolver.new(user: user, account: Current.account).resolve

    result.permissions.merge(
      userId: user.id,
      aclSource: result.acl_source,
      model: serialized_model(result.model)
    )
  end

  def serialized_model(model)
    return if model.blank?

    {
      id: model.id,
      name: model.name,
      description: model.description
    }
  end

  def normalized_permissions
    permissions = params.require(:permissions).permit!.to_h
    Virti::Acl::PermissionNormalizer.perform(permissions, strict: true)
  end

  def render_invalid_permissions(error)
    render json: { error: 'Invalid ACL permissions', details: error.errors }, status: :unprocessable_entity
  end
end
