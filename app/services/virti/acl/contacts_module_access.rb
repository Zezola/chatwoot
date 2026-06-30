module Virti::Acl::ContactsModuleAccess
  def self.allowed?(user:, account:)
    return true unless Virti::Acl.enabled?
    return true unless user.is_a?(User)
    return true if account.blank?

    permissions = Virti::Acl::PermissionsResolver.new(user: user, account: account).perform
    permissions['pode_ver_menu_contatos'] != false
  end
end
