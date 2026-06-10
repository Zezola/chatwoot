module Virti
  module Kanban
    class Model < ApplicationRecord
      self.table_name = 'virti_kanban_models'

      belongs_to :account
      belongs_to :created_by, class_name: 'User', optional: true
      belongs_to :updated_by, class_name: 'User', optional: true
      has_many :user_models, class_name: 'Virti::Kanban::UserModel', dependent: :restrict_with_error

      validates :name, presence: true, uniqueness: { scope: :account_id }
      validate :configuration_must_be_valid

      def normalized_configuration
        Virti::Kanban::ConfigurationNormalizer.perform(configuration, account: account)
      end

      private

      def configuration_must_be_valid
        Virti::Kanban::ConfigurationNormalizer.perform(configuration, account: account)
      rescue Virti::Kanban::ConfigurationNormalizer::InvalidConfigurationError => e
        errors.add(:configuration, e.errors)
      end
    end
  end
end
