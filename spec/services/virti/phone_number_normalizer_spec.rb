require 'rails_helper'

RSpec.describe Virti::PhoneNumberNormalizer do
  describe '.normalize' do
    it 'adds the Brazilian ninth digit for mobile numbers without plus' do
      expect(described_class.normalize('551195557780')).to eq('5511995557780')
    end

    it 'adds the Brazilian ninth digit preserving plus' do
      expect(described_class.normalize('+55 (11) 9555-7780')).to eq('+5511995557780')
    end

    it 'does not change Brazilian landline-like numbers' do
      expect(described_class.normalize('+551135557780')).to eq('+551135557780')
    end

    it 'does not change non-Brazilian numbers' do
      expect(described_class.normalize('+14155552671')).to eq('+14155552671')
    end

    it 'forces plus when requested' do
      expect(described_class.normalize('551195557780', force_plus: true)).to eq('+5511995557780')
    end
  end

  describe '.normalize_e164' do
    it 'normalizes Brazilian mobile numbers without plus to E.164' do
      expect(described_class.normalize_e164('551195557780')).to eq('+5511995557780')
    end

    it 'does not add plus to arbitrary non-Brazilian values' do
      expect(described_class.normalize_e164('123456789')).to eq('123456789')
    end
  end
end
