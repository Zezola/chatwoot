require 'rails_helper'

RSpec.describe 'Virti ACL Permission Definitions API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/:account_id/virti/acl/permission_definitions' do
    it 'returns the supported ACL permission catalog' do
      get "/api/v1/accounts/#{account.id}/virti/acl/permission_definitions", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      kanban_permission = response.parsed_body.find { |permission| permission['key'] == 'pode_ver_menu_kanban' }
      expect(kanban_permission).to include(
        'label' => 'Ver menu Kanban',
        'group' => 'Menu lateral',
        'default' => true
      )
    end
  end
end
