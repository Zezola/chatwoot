module Virti
  module Acl
    class PermissionsResolver
      Result = Struct.new(:permissions, :acl_source, :model, keyword_init: true)

      def initialize(user:, account: nil)
        @user = user
        @account = account
      end

      def perform
        resolve.permissions
      end

      def resolve
        return Result.new(permissions: default_permissions, acl_source: 'disabled') unless Virti::Acl.enabled?

        model = user_model&.model
        if model.present?
          return Result.new(
            permissions: default_permissions.merge(model.normalized_permissions),
            acl_source: 'model',
            model: model
          )
        end

        permission_record = legacy_user_permission_record
        if permission_record.present?
          return Result.new(
            permissions: default_permissions.merge(PermissionNormalizer.perform(permission_record.permissions)),
            acl_source: 'individual'
          )
        end

        Result.new(permissions: default_permissions, acl_source: 'default')
      end

      private

      attr_reader :user, :account

      def default_permissions
        @default_permissions ||= DefaultPermissions.to_h
      end

      def user_model
        return if account.blank?
        return unless Model.table_exists? && UserModel.table_exists?

        @user_model ||= UserModel.includes(:model).find_by(account_id: account.id, user_id: user.id)
      end

      def legacy_user_permission_record
        @legacy_user_permission_record ||= UserPermission.active.find_by(IdUsuario: user.id)
      end
    end
  end
end
