require 'rails_helper'

RSpec.describe 'Virti ACL Permissions API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/:account_id/virti/acl' do
    it 'returns effective permissions for the current user' do
      Virti::Acl::UserPermission.create!(
        IdUsuario: agent.id,
        Permissoes: { 'pode_ver_menu_kanban' => false },
        CriadoEm: Time.current,
        AtualizadoEm: Time.current
      )

      get "/api/v1/accounts/#{account.id}/virti/acl", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['userId']).to eq(agent.id)
      expect(response.parsed_body['aclSource']).to eq('individual')
      expect(response.parsed_body['model']).to be_nil
      expect(response.parsed_body['pode_ver_menu_kanban']).to be false
      expect(response.parsed_body['pode_filtrar_sem_times']).to be true
    end

    it 'uses the ACL model assigned in the current account before legacy permissions' do
      model = create(:virti_acl_model, account: account, permissions: { 'pode_ver_menu_kanban' => true })
      create(:virti_acl_user_model, account: account, user: agent, model: model)
      Virti::Acl::UserPermission.create!(
        IdUsuario: agent.id,
        Permissoes: { 'pode_ver_menu_kanban' => false },
        CriadoEm: Time.current,
        AtualizadoEm: Time.current
      )

      get "/api/v1/accounts/#{account.id}/virti/acl", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['userId']).to eq(agent.id)
      expect(response.parsed_body['aclSource']).to eq('model')
      expect(response.parsed_body['model']['id']).to eq(model.id)
      expect(response.parsed_body['pode_ver_menu_kanban']).to be true
    end
  end

  describe 'GET /api/v1/accounts/:account_id/virti/acl/:user_id' do
    it 'allows administrators to read another user permissions' do
      get "/api/v1/accounts/#{account.id}/virti/acl/#{agent.id}", headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['userId']).to eq(agent.id)
      expect(response.parsed_body['aclSource']).to eq('default')
      expect(response.parsed_body['model']).to be_nil
      expect(response.parsed_body['pode_ver_menu_kanban']).to be true
    end

    it 'blocks non administrators' do
      get "/api/v1/accounts/#{account.id}/virti/acl/#{administrator.id}", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/virti/acl/:user_id' do
    it 'allows administrators to create or update permissions' do
      patch "/api/v1/accounts/#{account.id}/virti/acl/#{agent.id}",
            headers: administrator.create_new_auth_token,
            params: { permissions: { pode_ver_menu_kanban: false, time_privado: false } },
            as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['userId']).to eq(agent.id)
      expect(response.parsed_body['pode_ver_menu_kanban']).to be false
      expect(response.parsed_body).not_to have_key('time_privado')

      permission_record = Virti::Acl::UserPermission.find_by!(IdUsuario: agent.id)
      expect(permission_record.permissions).to eq('pode_ver_menu_kanban' => false)
    end

    it 'rejects unknown permission keys' do
      patch "/api/v1/accounts/#{account.id}/virti/acl/#{agent.id}",
            headers: administrator.create_new_auth_token,
            params: { permissions: { permissao_inexistente: false } },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('details', 'invalidKeys')).to eq(['permissao_inexistente'])
    end

    it 'rejects non-boolean permission values' do
      patch "/api/v1/accounts/#{account.id}/virti/acl/#{agent.id}",
            headers: administrator.create_new_auth_token,
            params: { permissions: { pode_ver_menu_kanban: 'false' } },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('details', 'invalidValues')).to eq(['pode_ver_menu_kanban'])
    end

    it 'blocks non administrators' do
      patch "/api/v1/accounts/#{account.id}/virti/acl/#{administrator.id}",
            headers: agent.create_new_auth_token,
            params: { permissions: { pode_ver_menu_kanban: false } },
            as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
