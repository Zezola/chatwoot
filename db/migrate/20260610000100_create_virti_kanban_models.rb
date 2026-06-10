class CreateVirtiKanbanModels < ActiveRecord::Migration[7.1]
  def change
    create_table :virti_kanban_models do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.jsonb :configuration, null: false, default: {}
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :virti_kanban_models, [:account_id, :name], unique: true

    create_table :virti_kanban_user_models do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :model, null: false, foreign_key: { to_table: :virti_kanban_models }
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :virti_kanban_user_models, [:account_id, :user_id], unique: true
  end
end
