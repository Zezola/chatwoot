require 'rails_helper'

RSpec.describe Contacts::BulkActionService do
  subject(:service) { described_class.new(account: account, user: user, params: params) }

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  describe '#perform' do
    context 'when delete action is requested via action_name' do
      let(:params) { { ids: [1, 2], action_name: 'delete' } }

      it 'delegates to the bulk delete service' do
        bulk_delete_service = instance_double(Contacts::BulkDeleteService, perform: true)

        expect(Contacts::BulkDeleteService).to receive(:new)
          .with(account: account, contact_ids: [1, 2])
          .and_return(bulk_delete_service)

        service.perform
      end
    end

    context 'when labels are provided' do
      let(:params) { { ids: [10, 20], labels: { add: %w[vip support] }, extra: 'ignored' } }

      it 'delegates to the bulk assign labels service with permitted params' do
        bulk_assign_service = instance_double(Contacts::BulkAssignLabelsService, perform: true)

        expect(Contacts::BulkAssignLabelsService).to receive(:new)
          .with(account: account, contact_ids: [10, 20], labels: %w[vip support])
          .and_return(bulk_assign_service)

        service.perform
      end

      it 'documents current label assignment to contacts outside Virti ACL scope' do
        hidden_contact = create(:contact, account: account)
        create_contact_outside_virti_acl_for(user, hidden_contact)

        described_class.new(
          account: account,
          user: user,
          params: { ids: [hidden_contact.id], labels: { add: ['hidden_acl'] } }
        ).perform

        expect(hidden_contact.reload.label_list).to include('hidden_acl')
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
