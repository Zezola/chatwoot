require 'rails_helper'

RSpec.describe Virti::Acl::ContactPolicy do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let(:own_contact) { create(:contact, account: account) }
  let(:unassigned_contact) { create(:contact, account: account) }
  let(:other_contact) { create(:contact, account: account) }

  before do
    create(:conversation, account: account, inbox: inbox, contact: own_contact, assignee: agent)
    create(:conversation, account: account, inbox: inbox, contact: unassigned_contact, assignee: nil)
    create(:conversation, account: account, inbox: inbox, contact: other_contact, assignee: other_agent)
  end

  describe '#show?' do
    it 'allows contacts by default when user has no model or legacy ACL' do
      expect(policy_for(other_contact).show?).to be true
    end

    it 'allows contacts with assigned conversations for restricted users' do
      restrict_agent(allow_unassigned: false)

      expect(policy_for(own_contact).show?).to be true
    end

    it 'denies contacts without visible conversations for restricted users' do
      restrict_agent(allow_unassigned: false)

      expect(policy_for(other_contact).show?).to be false
      expect(policy_for(unassigned_contact).show?).to be false
    end

    it 'allows contacts with unassigned conversations when permission allows unassigned conversations' do
      restrict_agent(allow_unassigned: true)

      expect(policy_for(unassigned_contact).show?).to be true
      expect(policy_for(other_contact).show?).to be false
    end

    it 'checks visibility by contact id when the contact record is no longer available' do
      restrict_agent(allow_unassigned: false)

      expect(policy_for_contact_id(own_contact.id).show?).to be true
      expect(policy_for_contact_id(other_contact.id).show?).to be false
    end
  end

  def policy_for(contact)
    described_class.new(user: agent, account: account, contact: contact)
  end

  def policy_for_contact_id(contact_id)
    described_class.new(user: agent, account: account, contact_id: contact_id)
  end

  def restrict_agent(allow_unassigned:)
    model = create(
      :virti_acl_model,
      account: account,
      permissions: {
        'pode_ver_aba_de_todas_conversas' => false,
        'pode_ver_aba_de_nao_atribuidas' => allow_unassigned
      }
    )
    create(:virti_acl_user_model, account: account, user: agent, model: model)
  end
end
