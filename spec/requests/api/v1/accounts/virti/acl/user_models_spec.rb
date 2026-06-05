require 'rails_helper'

RSpec.describe 'Virti ACL User Models API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/:account_id/virti/acl/users/:user_id/model' do
    it 'returns the assigned model and effective permissions' do
      model = create(:virti_acl_model, account: account, name: 'Gestor', permissions: { 'pode_ver_menu_kanban' => false })
      create(:virti_acl_user_model, account: account, user: agent, model: model)

      get "/api/v1/accounts/#{account.id}/virti/acl/users/#{agent.id}/model", headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['aclSource']).to eq('model')
      expect(response.parsed_body['model']['name']).to eq('Gestor')
      expect(response.parsed_body['permissions']['pode_ver_menu_kanban']).to be false
    end
  end

  describe 'PUT /api/v1/accounts/:account_id/virti/acl/users/:user_id/model' do
    it 'assigns a model to a user in the account' do
      model = create(:virti_acl_model, account: account, name: 'Gestor', permissions: { 'pode_ver_menu_kanban' => false })

      put "/api/v1/accounts/#{account.id}/virti/acl/users/#{agent.id}/model",
          headers: administrator.create_new_auth_token,
          params: { model_id: model.id },
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['aclSource']).to eq('model')
      expect(response.parsed_body['model']['id']).to eq(model.id)
      expect(response.parsed_body['permissions']['pode_ver_menu_kanban']).to be false
    end

    it 'does not assign models from another account' do
      other_model = create(:virti_acl_model)

      put "/api/v1/accounts/#{account.id}/virti/acl/users/#{agent.id}/model",
          headers: administrator.create_new_auth_token,
          params: { model_id: other_model.id },
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/virti/acl/users/:user_id/model' do
    it 'removes the assigned model from a user' do
      model = create(:virti_acl_model, account: account)
      create(:virti_acl_user_model, account: account, user: agent, model: model)

      delete "/api/v1/accounts/#{account.id}/virti/acl/users/#{agent.id}/model", headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
      expect(Virti::Acl::UserModel.find_by(account: account, user: agent)).to be_nil
    end
  end
end
