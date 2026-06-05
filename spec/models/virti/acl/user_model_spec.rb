require 'rails_helper'

RSpec.describe Virti::Acl::UserModel do
  describe 'validations' do
    it 'allows one model per user per account' do
      account = create(:account)
      user = create(:user, account: account)
      model = create(:virti_acl_model, account: account)
      create(:virti_acl_user_model, account: account, user: user, model: model)

      duplicate = build(:virti_acl_user_model, account: account, user: user, model: model)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it 'requires model to belong to the same account' do
      account = create(:account)
      user = create(:user, account: account)
      other_model = create(:virti_acl_model)

      user_model = build(:virti_acl_user_model, account: account, user: user, model: other_model)

      expect(user_model).not_to be_valid
      expect(user_model.errors[:model]).to be_present
    end

    it 'requires user to belong to the account' do
      account = create(:account)
      user = create(:user)
      model = create(:virti_acl_model, account: account)

      user_model = build(:virti_acl_user_model, account: account, user: user, model: model)

      expect(user_model).not_to be_valid
      expect(user_model.errors[:user]).to be_present
    end
  end
end
