class RemoveDiscardedAtFromVirtiAclProfiles < ActiveRecord::Migration[7.1]
  def change
    remove_column :virti_acl_profiles, :discarded_at, :datetime if table_exists?(:virti_acl_profiles) && column_exists?(:virti_acl_profiles, :discarded_at)
    remove_column :virti_acl_models, :discarded_at, :datetime if table_exists?(:virti_acl_models) && column_exists?(:virti_acl_models, :discarded_at)
  end
end
