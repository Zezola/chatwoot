module Virti
  module Acl
    class UserPermission < ApplicationRecord
      self.table_name = 'Virti_UsuarioACL'
      self.primary_key = 'Id'

      belongs_to :user, class_name: 'User', foreign_key: 'IdUsuario', inverse_of: false

      scope :active, -> { where(DeletadoEm: nil) }

      def permissions
        raw_permissions = self[:Permissoes]
        return {} if raw_permissions.blank?

        raw_permissions.is_a?(String) ? JSON.parse(raw_permissions) : raw_permissions
      end
    end
  end
end
