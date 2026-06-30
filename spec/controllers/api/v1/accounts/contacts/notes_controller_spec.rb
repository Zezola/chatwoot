require 'rails_helper'

RSpec.describe 'Notes API', type: :request do
  let!(:account) { create(:account) }
  let!(:contact) { create(:contact, account: account) }
  let!(:note) { create(:note, contact: contact) }
  let!(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/contacts/{contact.id}/notes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all notes to agents' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body.first[:content]).to eq(note.content)
      end

      it 'respects Virti ACL scope when listing contact notes' do
        create_contact_outside_virti_acl_for(agent, contact)

        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'blocks access to contact notes when Virti contacts menu is disabled' do
        disable_virti_contacts_menu_for(agent)

        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/{contact.id}/notes/{note.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'shows the note for agents' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:id]).to eq(note.id)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts/{contact.id}/notes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes",
             params: { content: 'test message' },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates a new note' do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes",
             params: { content: 'test note' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:content]).to eq('test note')
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/contacts/{contact.id}/notes/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}",
              params: { content: 'test message' },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates the note' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}",
              params: { content: 'test message' },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:content]).to eq('test message')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/notes/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}",
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'delete note if agent' do
        delete "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/notes/#{note.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(Note.exists?(note.id)).to be false
      end
    end
  end

  def create_contact_outside_virti_acl_for(user, contact)
    other_agent = create(:user, account: account, role: :agent)
    inbox = create(:inbox, account: account)

    create(:inbox_member, user: user, inbox: inbox)
    create(:conversation, account: account, inbox: inbox, contact: contact, assignee: other_agent)
    restrict_virti_acl_to_assigned_conversations(user)

    expect(Virti::Acl::ContactPolicy.new(user: user, account: account, contact: contact).show?).to be(false)
  end

  def restrict_virti_acl_to_assigned_conversations(user)
    model = create(
      :virti_acl_model,
      account: account,
      permissions: {
        'pode_ver_aba_de_todas_conversas' => false,
        'pode_ver_aba_de_nao_atribuidas' => false
      }
    )
    create(:virti_acl_user_model, account: account, user: user, model: model)
  end

  def disable_virti_contacts_menu_for(user)
    model = create(
      :virti_acl_model,
      account: account,
      permissions: { 'pode_ver_menu_contatos' => false }
    )
    create(:virti_acl_user_model, account: account, user: user, model: model)

    permissions = Virti::Acl::PermissionsResolver.new(user: user, account: account).perform
    expect(permissions['pode_ver_menu_contatos']).to be(false)
  end
end
