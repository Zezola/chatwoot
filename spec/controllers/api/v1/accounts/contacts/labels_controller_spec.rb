require 'rails_helper'

RSpec.describe 'Contact Label API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/contacts/<id>/labels' do
    let(:contact) { create(:contact, account: account) }

    before do
      contact.update_labels('label1, label2')
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get api_v1_account_contact_labels_url(account_id: account.id, contact_id: contact.id)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all the labels for the contact' do
        get api_v1_account_contact_labels_url(account_id: account.id, contact_id: contact.id),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('label1')
        expect(response.body).to include('label2')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts/<id>/labels' do
    let(:contact) { create(:contact, account: account) }

    before do
      contact.update_labels('label1, label2')
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post api_v1_account_contact_labels_url(account_id: account.id, contact_id: contact.id),
             params: { labels: %w[label3 label4] },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'creates labels for the contact' do
        post api_v1_account_contact_labels_url(account_id: account.id, contact_id: contact.id),
             params: { labels: %w[label3 label4] },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('label3')
        expect(response.body).to include('label4')
      end

      it 'respects Virti ACL scope when updating contact labels' do
        create_contact_outside_virti_acl_for(agent, contact)

        post api_v1_account_contact_labels_url(account_id: account.id, contact_id: contact.id),
             params: { labels: %w[label3 label4] },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:forbidden)
        expect(contact.reload.label_list).not_to include('label3', 'label4')
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
end
