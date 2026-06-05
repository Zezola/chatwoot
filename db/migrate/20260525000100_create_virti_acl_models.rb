class CreateVirtiAclModels < ActiveRecord::Migration[7.1]
  def change
    create_legacy_user_permissions_table unless table_exists?('Virti_UsuarioACL')

    create_table :virti_acl_models do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.jsonb :permissions, null: false, default: {}
      t.bigint :created_by_id
      t.bigint :updated_by_id
      t.timestamps
    end

    add_index :virti_acl_models, [:account_id, :name], unique: true
    add_foreign_key :virti_acl_models, :users, column: :created_by_id
    add_foreign_key :virti_acl_models, :users, column: :updated_by_id

    create_table :virti_acl_user_models do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.references :model, null: false, foreign_key: { to_table: :virti_acl_models }, index: true
      t.bigint :created_by_id
      t.bigint :updated_by_id
      t.timestamps
    end

    add_index :virti_acl_user_models, [:account_id, :user_id], unique: true
    add_foreign_key :virti_acl_user_models, :users, column: :created_by_id
    add_foreign_key :virti_acl_user_models, :users, column: :updated_by_id
  end

  private

  def create_legacy_user_permissions_table
    create_table 'Virti_UsuarioACL', primary_key: 'Id', id: :serial do |t|
      t.integer 'IdUsuario', null: false
      t.json 'Permissoes', null: false
      t.datetime 'CriadoEm', null: false
      t.datetime 'AtualizadoEm', null: false
      t.datetime 'DeletadoEm'
    end

    add_index 'Virti_UsuarioACL', 'IdUsuario', unique: true, name: 'Virti_UsuarioACL_IdUsuario_key'
    add_foreign_key 'Virti_UsuarioACL', :users, column: 'IdUsuario', name: 'fk_permissoes_ats_usuario', on_delete: :cascade
  end
end
