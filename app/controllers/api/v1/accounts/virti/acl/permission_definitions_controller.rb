class Api::V1::Accounts::Virti::Acl::PermissionDefinitionsController < Api::V1::Accounts::BaseController
  def index
    render json: Virti::Acl::PermissionDefinitions.to_a
  end
end
