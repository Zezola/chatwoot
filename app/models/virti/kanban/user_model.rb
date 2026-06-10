module Virti
  module Kanban
    class UserModel < ApplicationRecord
      self.table_name = 'virti_kanban_user_models'

      belongs_to :account
      belongs_to :user
      belongs_to :model, class_name: 'Virti::Kanban::Model'
      belongs_to :created_by, class_name: 'User', optional: true
      belongs_to :updated_by, class_name: 'User', optional: true

      validates :user_id, uniqueness: { scope: :account_id }
      validate :user_must_belong_to_account
      validate :model_must_belong_to_account

      private

      def user_must_belong_to_account
        return if account.blank? || user.blank? || account.users.exists?(user.id)

        errors.add(:user, 'must belong to account')
      end

      def model_must_belong_to_account
        return if account.blank? || model.blank? || model.account_id == account_id

        errors.add(:model, 'must belong to account')
      end
    end
  end
end
