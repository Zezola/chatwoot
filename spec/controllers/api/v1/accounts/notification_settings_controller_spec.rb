require 'rails_helper'

RSpec.describe 'Notification Settings API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/notification_settings' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/notification_settings"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns current user notification settings' do
        get "/api/v1/accounts/#{account.id}/notification_settings",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['user_id']).to eq(agent.id)
        expect(json_response['account_id']).to eq(account.id)
      end

      it 'returns mandatory agent push flags even when saved flags are empty' do
        notification_setting = agent.notification_settings.find_by(account_id: account.id)
        notification_setting.selected_push_flags = []
        notification_setting.save!

        get "/api/v1/accounts/#{account.id}/notification_settings",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['selected_push_flags']).to match_array(NotificationSetting::MANDATORY_AGENT_PUSH_NOTIFICATION_FLAGS)
      end

      it 'does not force mandatory push flags for administrators' do
        admin = create(:user, account: account, role: :administrator)
        notification_setting = admin.notification_settings.find_by(account_id: account.id)
        notification_setting.selected_push_flags = []
        notification_setting.save!

        get "/api/v1/accounts/#{account.id}/notification_settings",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['selected_push_flags']).to eq([])
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/notification_settings' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/notification_settings"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'updates the email related notification flags' do
        put "/api/v1/accounts/#{account.id}/notification_settings",
            params: { notification_settings: { selected_email_flags: ['email_conversation_assignment'] } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        agent.reload
        expect(json_response['user_id']).to eq(agent.id)
        expect(json_response['account_id']).to eq(account.id)
        expect(json_response['selected_email_flags']).to eq(['email_conversation_assignment'])
      end

      it 'keeps mandatory agent push flags enabled' do
        put "/api/v1/accounts/#{account.id}/notification_settings",
            params: { notification_settings: { selected_push_flags: [] } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['selected_push_flags']).to match_array(NotificationSetting::MANDATORY_AGENT_PUSH_NOTIFICATION_FLAGS)
        expect(json_response['selected_push_flags']).not_to include('push_conversation_creation')
        expect(json_response['selected_push_flags']).not_to include('push_assigned_conversation_new_message')
        expect(json_response['selected_push_flags']).not_to include('push_sla_missed_first_response')
      end

      it 'allows administrators to turn off push flags' do
        admin = create(:user, account: account, role: :administrator)

        put "/api/v1/accounts/#{account.id}/notification_settings",
            params: { notification_settings: { selected_push_flags: [] } },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['selected_push_flags']).to eq([])
      end
    end
  end
end
