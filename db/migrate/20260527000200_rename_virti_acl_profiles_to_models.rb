class RenameVirtiAclProfilesToModels < ActiveRecord::Migration[7.1]
  def change
    rename_table :virti_acl_profiles, :virti_acl_models if table_exists?(:virti_acl_profiles) && !table_exists?(:virti_acl_models)
    rename_table :virti_acl_user_profiles, :virti_acl_user_models if table_exists?(:virti_acl_user_profiles) && !table_exists?(:virti_acl_user_models)

    if table_exists?(:virti_acl_user_models) && column_exists?(:virti_acl_user_models, :profile_id) && !column_exists?(:virti_acl_user_models, :model_id)
      rename_column :virti_acl_user_models, :profile_id, :model_id
    end

    rename_index :virti_acl_models,
                 'index_virti_acl_profiles_on_account_id_and_name',
                 'index_virti_acl_models_on_account_id_and_name' if index_name_exists?(:virti_acl_models, 'index_virti_acl_profiles_on_account_id_and_name')

    rename_index :virti_acl_models,
                 'index_virti_acl_profiles_on_account_id',
                 'index_virti_acl_models_on_account_id' if index_name_exists?(:virti_acl_models, 'index_virti_acl_profiles_on_account_id')

    rename_index :virti_acl_user_models,
                 'index_virti_acl_user_profiles_on_account_id_and_user_id',
                 'index_virti_acl_user_models_on_account_id_and_user_id' if index_name_exists?(:virti_acl_user_models, 'index_virti_acl_user_profiles_on_account_id_and_user_id')

    rename_index :virti_acl_user_models,
                 'index_virti_acl_user_profiles_on_account_id',
                 'index_virti_acl_user_models_on_account_id' if index_name_exists?(:virti_acl_user_models, 'index_virti_acl_user_profiles_on_account_id')

    rename_index :virti_acl_user_models,
                 'index_virti_acl_user_profiles_on_profile_id',
                 'index_virti_acl_user_models_on_model_id' if index_name_exists?(:virti_acl_user_models, 'index_virti_acl_user_profiles_on_profile_id')

    rename_index :virti_acl_user_models,
                 'index_virti_acl_user_profiles_on_user_id',
                 'index_virti_acl_user_models_on_user_id' if index_name_exists?(:virti_acl_user_models, 'index_virti_acl_user_profiles_on_user_id')
  end
end
