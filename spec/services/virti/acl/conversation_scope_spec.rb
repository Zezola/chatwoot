require 'rails_helper'

RSpec.describe Virti::Acl::ConversationScope do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:own_conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }
  let!(:unassigned_conversation) { create(:conversation, account: account, inbox: inbox, assignee: nil) }
  let!(:other_conversation) { create(:conversation, account: account, inbox: inbox, assignee: create(:user, account: account)) }

  describe '#perform' do
    it 'applies assigned ACL models to administrators' do
      admin = create(:user, account: account, role: :administrator)
      model = create(
        :virti_acl_model,
        account: account,
        permissions: { 'pode_ver_aba_de_todas_conversas' => false, 'pode_ver_aba_de_nao_atribuidas' => false }
      )
      create(:virti_acl_user_model, account: account, user: admin, model: model)
      own_admin_conversation = create(:conversation, account: account, inbox: inbox, assignee: admin)

      result = described_class.new(scope: account.conversations, user: admin, account: account).perform

      expect(result).to contain_exactly(own_admin_conversation)
    end

    it 'returns the original scope when user has no model or legacy ACL' do
      result = described_class.new(scope: account.conversations, user: agent, account: account).perform

      expect(result).to include(own_conversation, unassigned_conversation, other_conversation)
    end

    it 'allows all conversations when permission allows all conversations' do
      model = create(:virti_acl_model, account: account, permissions: { 'pode_ver_aba_de_todas_conversas' => true })
      create(:virti_acl_user_model, account: account, user: agent, model: model)

      result = described_class.new(scope: account.conversations, user: agent, account: account).perform

      expect(result).to include(own_conversation, unassigned_conversation, other_conversation)
    end

    it 'returns only assigned conversations when all-conversations and unassigned permissions are disabled' do
      model = create(
        :virti_acl_model,
        account: account,
        permissions: { 'pode_ver_aba_de_todas_conversas' => false, 'pode_ver_aba_de_nao_atribuidas' => false }
      )
      create(:virti_acl_user_model, account: account, user: agent, model: model)

      result = described_class.new(scope: account.conversations, user: agent, account: account).perform

      expect(result).to contain_exactly(own_conversation)
    end

    it 'includes unassigned conversations when permission allows unassigned conversations' do
      model = create(
        :virti_acl_model,
        account: account,
        permissions: { 'pode_ver_aba_de_todas_conversas' => false, 'pode_ver_aba_de_nao_atribuidas' => true }
      )
      create(:virti_acl_user_model, account: account, user: agent, model: model)

      result = described_class.new(scope: account.conversations, user: agent, account: account).perform

      expect(result).to include(own_conversation, unassigned_conversation)
      expect(result).not_to include(other_conversation)
    end
  end
end
