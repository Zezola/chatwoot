require 'rails_helper'

RSpec.describe Virti::Acl::Model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }

    it 'requires permissions to be present' do
      model = build(:virti_acl_model, permissions: {})

      expect(model).not_to be_valid
      expect(model.errors[:permissions]).to be_present
    end

    it 'requires name to be unique per account' do
      account = create(:account)
      create(:virti_acl_model, account: account, name: 'Gestor')

      duplicate = build(:virti_acl_model, account: account, name: 'Gestor')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it 'allows the same name in different accounts' do
      create(:virti_acl_model, name: 'Gestor')
      model = build(:virti_acl_model, name: 'Gestor')

      expect(model).to be_valid
    end
  end

  describe '#normalized_permissions' do
    it 'removes legacy keys' do
      model = build(:virti_acl_model, permissions: { 'time_privado' => false, 'pode_ver_menu_kanban' => false })

      expect(model.normalized_permissions).to eq('pode_ver_menu_kanban' => false)
    end
  end
end
