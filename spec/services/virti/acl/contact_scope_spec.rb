require 'rails_helper'

RSpec.describe Virti::Acl::ContactScope do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let(:own_contact) { create(:contact, account: account) }
  let(:unassigned_contact) { create(:contact, account: account) }
  let(:other_contact) { create(:contact, account: account) }
  let(:standalone_contact) { create(:contact, account: account) }

  before do
    create(:conversation, account: account, inbox: inbox, contact: own_contact, assignee: agent)
    create(:conversation, account: account, inbox: inbox, contact: unassigned_contact, assignee: nil)
    create(:conversation, account: account, inbox: inbox, contact: other_contact, assignee: other_agent)
    standalone_contact
  end

  describe '#perform' do
    it 'returns the original scope when user has no model or legacy ACL' do
      result = described_class.new(scope: account.contacts, user: agent, account: account).perform

      expect(result).to include(own_contact, unassigned_contact, other_contact, standalone_contact)
    end

    it 'allows all contacts when permission allows all conversations' do
      model = create(:virti_acl_model, account: account, permissions: { 'pode_ver_aba_de_todas_conversas' => true })
      create(:virti_acl_user_model, account: account, user: agent, model: model)

      result = described_class.new(scope: account.contacts, user: agent, account: account).perform

      expect(result).to include(own_contact, unassigned_contact, other_contact, standalone_contact)
    end

    it 'returns only contacts with assigned conversations when all-conversations and unassigned permissions are disabled' do
      model = create(
        :virti_acl_model,
        account: account,
        permissions: { 'pode_ver_aba_de_todas_conversas' => false, 'pode_ver_aba_de_nao_atribuidas' => false }
      )
      create(:virti_acl_user_model, account: account, user: agent, model: model)

      result = described_class.new(scope: account.contacts, user: agent, account: account).perform

      expect(result).to contain_exactly(own_contact)
    end

    it 'includes contacts with unassigned conversations when permission allows unassigned conversations' do
      model = create(
        :virti_acl_model,
        account: account,
        permissions: { 'pode_ver_aba_de_todas_conversas' => false, 'pode_ver_aba_de_nao_atribuidas' => true }
      )
      create(:virti_acl_user_model, account: account, user: agent, model: model)

      result = described_class.new(scope: account.contacts, user: agent, account: account).perform

      expect(result).to include(own_contact, unassigned_contact)
      expect(result).not_to include(other_contact, standalone_contact)
    end
  end
end
