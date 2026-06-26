require 'rails_helper'

RSpec.describe Virti::Acl::Patches::SearchServicePatch do
  describe 'SearchService integration' do
    let(:account) { create(:account) }
    let(:admin) { create(:user) }
    let(:inbox) { create(:inbox, account: account) }
    let(:token) { 'ACL Admin Search Scope' }

    before do
      create(:account_user, account: account, user: admin, role: :administrator)
      Current.account = account
    end

    after do
      Current.account = nil
    end

    it 'applies restrictive conversation ACL to administrators without requiring inbox membership' do
      model = create(
        :virti_acl_model,
        account: account,
        permissions: { 'pode_ver_aba_de_todas_conversas' => false, 'pode_ver_aba_de_nao_atribuidas' => false }
      )
      create(:virti_acl_user_model, account: account, user: admin, model: model)

      own_contact = create(:contact, name: token, email: 'acl-admin-own@example.com', account: account)
      other_contact = create(:contact, name: token, email: 'acl-admin-other@example.com', account: account)
      own_conversation = create(:conversation, contact: own_contact, inbox: inbox, account: account, assignee: admin)
      other_conversation = create(:conversation, contact: other_contact, inbox: inbox, account: account, assignee: create(:user, account: account))
      own_message = create(:message, conversation: own_conversation, inbox: inbox, account: account, content: token)
      other_message = create(:message, conversation: other_conversation, inbox: inbox, account: account, content: token)

      results = SearchService.new(current_user: admin, current_account: account, params: { q: token }, search_type: 'all').perform

      expect(results[:contacts]).to contain_exactly(own_contact)
      expect(results[:conversations]).to contain_exactly(own_conversation)
      expect(results[:messages]).to contain_exactly(own_message)
      expect(results[:messages]).not_to include(other_message)
    end
  end
end
