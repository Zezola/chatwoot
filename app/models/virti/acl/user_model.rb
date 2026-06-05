module Virti
  module Acl
    class UserModel < ApplicationRecord
      self.table_name = 'virti_acl_user_models'

      belongs_to :account
      belongs_to :user
      belongs_to :model, class_name: 'Virti::Acl::Model'
      belongs_to :created_by, class_name: 'User', optional: true
      belongs_to :updated_by, class_name: 'User', optional: true

      validates :user_id, uniqueness: { scope: :account_id }
      validate :model_belongs_to_same_account
      validate :user_belongs_to_account

      private

      def model_belongs_to_same_account
        return if model.blank? || account.blank? || model.account_id == account_id

        errors.add(:model, 'must belong to the same account')
      end

      def user_belongs_to_account
        return if user.blank? || account.blank? || account.account_users.exists?(user_id: user_id)

        errors.add(:user, 'must belong to the account')
      end
    end
  end
end
