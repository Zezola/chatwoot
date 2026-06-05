require 'rails_helper'

RSpec.describe DataImport::ContactManager do
  let(:account) { create(:account) }
  let(:manager) { described_class.new(account) }

  describe '#build_contact' do
    it 'normalizes Brazilian mobile phone numbers missing the ninth digit' do
      contact = manager.build_contact({ phone_number: '552184655502', name: 'Lead' })

      expect(contact.phone_number).to eq('+5521984655502')
    end
  end

  describe '#find_existing_contact' do
    it 'finds existing contacts using the normalized phone number' do
      existing_contact = create(:contact, account: account, phone_number: '+5521984655502')

      expect(manager.find_existing_contact({ phone_number: '552184655502' })).to eq(existing_contact)
    end
  end
end
