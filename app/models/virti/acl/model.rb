module Virti
  module Acl
    class Model < ApplicationRecord
      self.table_name = 'virti_acl_models'

      belongs_to :account
      belongs_to :created_by, class_name: 'User', optional: true
      belongs_to :updated_by, class_name: 'User', optional: true
      has_many :user_models, class_name: 'Virti::Acl::UserModel', dependent: :restrict_with_error

      validates :name, presence: true, uniqueness: { scope: :account_id }
      validate :permissions_must_not_be_empty

      def normalized_permissions
        PermissionNormalizer.perform(permissions)
      end

      private

      def permissions_must_not_be_empty
        return if permissions.present?

        errors.add(:permissions, 'must not be empty')
      end
    end
  end
end
