require 'rails_helper'

RSpec.describe Conversations::PermissionFilterService do
  let(:account) { create(:account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:another_conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:inbox) { create(:inbox, account: account) }

  # This inbox_member is used to establish the agent's access to the inbox
  before { create(:inbox_member, user: agent, inbox: inbox) }

  describe '#perform' do
    context 'when user is an administrator' do
      it 'returns all conversations' do
        result = described_class.new(
          account.conversations,
          admin,
          account
        ).perform

        expect(result).to include(conversation)
        expect(result).to include(another_conversation)
        expect(result.count).to eq(2)
      end
    end

    context 'when user is an agent' do
      it 'returns all conversations with no further filtering' do
        inbox_ids = agent.inboxes.where(account_id: account.id).pluck(:id)

        # The base implementation returns all conversations
        # expecting the caller to filter by assigned inboxes
        result = described_class.new(
          account.conversations.where(inbox_id: inbox_ids),
          agent,
          account
        ).perform

        expect(result).to include(conversation)
        expect(result).to include(another_conversation)
        expect(result.count).to eq(2)
      end

      it 'applies Virti ACL conversation scope when ACL is enabled' do
        conversation.update!(assignee: agent)
        another_conversation.update!(assignee: create(:user, account: account))
        model = create(
          :virti_acl_model,
          account: account,
          permissions: { 'pode_ver_aba_de_todas_conversas' => false, 'pode_ver_aba_de_nao_atribuidas' => false }
        )
        create(:virti_acl_user_model, account: account, user: agent, model: model)

        result = described_class.new(
          account.conversations,
          agent,
          account
        ).perform

        expect(result).to contain_exactly(conversation)
      end

      it 'does not apply Virti ACL conversation scope when ACL is disabled' do
        conversation.update!(assignee: agent)
        another_conversation.update!(assignee: create(:user, account: account))
        model = create(
          :virti_acl_model,
          account: account,
          permissions: { 'pode_ver_aba_de_todas_conversas' => false, 'pode_ver_aba_de_nao_atribuidas' => false }
        )
        create(:virti_acl_user_model, account: account, user: agent, model: model)

        with_modified_env VIRTI_ACL_ENABLED: 'false' do
          result = described_class.new(
            account.conversations,
            agent,
            account
          ).perform

          expect(result).to include(conversation, another_conversation)
        end
      end
    end
  end
end
