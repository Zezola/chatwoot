require 'rails_helper'

RSpec.describe 'Virti ACL Models API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/:account_id/virti/acl/models' do
    it 'lists ACL models for administrators' do
      model = create(:virti_acl_model, account: account, name: 'Gestor')
      create(:virti_acl_user_model, account: account, user: agent, model: model)

      get "/api/v1/accounts/#{account.id}/virti/acl/models", headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      model_response = response.parsed_body.find { |item| item['name'] == 'Gestor' }
      expect(model_response['usersCount']).to eq(1)
    end

    it 'blocks non administrators' do
      get "/api/v1/accounts/#{account.id}/virti/acl/models", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/virti/acl/models' do
    it 'creates a custom ACL model' do
      post "/api/v1/accounts/#{account.id}/virti/acl/models",
           headers: administrator.create_new_auth_token,
           params: { model: { name: 'Gestor', description: 'Gestor comercial', permissions: { pode_ver_menu_kanban: false } } },
           as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['name']).to eq('Gestor')
      expect(response.parsed_body['permissions']).to eq('pode_ver_menu_kanban' => false)
    end

    it 'rejects unknown permission keys' do
      post "/api/v1/accounts/#{account.id}/virti/acl/models",
           headers: administrator.create_new_auth_token,
           params: { model: { name: 'Gestor', permissions: { permissao_inexistente: false } } },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('details', 'invalidKeys')).to eq(['permissao_inexistente'])
    end

    it 'rejects non-boolean permission values' do
      post "/api/v1/accounts/#{account.id}/virti/acl/models",
           headers: administrator.create_new_auth_token,
           params: { model: { name: 'Gestor', permissions: { pode_ver_menu_kanban: 'false' } } },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('details', 'invalidValues')).to eq(['pode_ver_menu_kanban'])
    end

    it 'rejects missing permissions' do
      post "/api/v1/accounts/#{account.id}/virti/acl/models",
           headers: administrator.create_new_auth_token,
           params: { model: { name: 'Gestor' } },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('details', 'empty')).to be true
    end

    it 'rejects empty permissions' do
      post "/api/v1/accounts/#{account.id}/virti/acl/models",
           headers: administrator.create_new_auth_token,
           params: { model: { name: 'Gestor', permissions: {} } },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('details', 'empty')).to be true
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/virti/acl/models/:id' do
    it 'updates a custom ACL model' do
      model = create(:virti_acl_model, account: account, name: 'Gestor')

      patch "/api/v1/accounts/#{account.id}/virti/acl/models/#{model.id}",
            headers: administrator.create_new_auth_token,
            params: { model: { name: 'Supervisor', permissions: { time_privado: false, pode_ver_menu_kanban: false } } },
            as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['name']).to eq('Supervisor')
      expect(response.parsed_body['permissions']).to eq('pode_ver_menu_kanban' => false)
    end

    it 'keeps existing permissions when permissions are omitted' do
      model = create(:virti_acl_model, account: account, name: 'Gestor', permissions: { 'pode_ver_menu_kanban' => false })

      patch "/api/v1/accounts/#{account.id}/virti/acl/models/#{model.id}",
            headers: administrator.create_new_auth_token,
            params: { model: { name: 'Supervisor' } },
            as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['name']).to eq('Supervisor')
      expect(response.parsed_body['permissions']).to eq('pode_ver_menu_kanban' => false)
      expect(model.reload.permissions).to eq('pode_ver_menu_kanban' => false)
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/virti/acl/models/:id' do
    it 'deletes an unused custom ACL model' do
      model = create(:virti_acl_model, account: account)

      delete "/api/v1/accounts/#{account.id}/virti/acl/models/#{model.id}", headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
      expect(Virti::Acl::Model.exists?(model.id)).to be false
    end

    it 'does not delete a model in use' do
      model = create(:virti_acl_model, account: account)
      create(:virti_acl_user_model, account: account, user: agent, model: model)

      delete "/api/v1/accounts/#{account.id}/virti/acl/models/#{model.id}", headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:conflict)
      expect(Virti::Acl::Model.exists?(model.id)).to be true
    end

    it 'allows reusing a model name after deletion' do
      model = create(:virti_acl_model, account: account, name: 'Gestor')
      delete "/api/v1/accounts/#{account.id}/virti/acl/models/#{model.id}", headers: administrator.create_new_auth_token, as: :json

      post "/api/v1/accounts/#{account.id}/virti/acl/models",
           headers: administrator.create_new_auth_token,
           params: { model: { name: 'Gestor', permissions: { pode_ver_menu_kanban: false } } },
           as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['name']).to eq('Gestor')
    end
  end
end
