class AddCorporateActionOnPortfolioTracker < ActiveRecord::Migration
  def change
    create_table :bonus_transactions do |t|
      t.integer :source_transaction_id
      t.integer :bonus_id
      t.integer :bonus_action_id
    end

    add_foreign_key(:bonus_transactions, :equity_transactions, column: :source_transaction_id, dependent: :delete)
    add_foreign_key(:bonus_transactions, :equity_transactions, column: :bonus_id, dependent: :delete)
    add_foreign_key(:bonus_transactions, :bonus_actions)
    add_index :bonus_transactions, [:bonus_action_id, :source_transaction_id], unique: true, name: :idx_unique_bonus_txn

    create_join_table :equity_transaction, :face_value_action, table_name: :face_value_transactions

    add_foreign_key(:face_value_transactions, :face_value_actions)
    add_foreign_key(:face_value_transactions, :equity_transactions)
    add_index :face_value_transactions, [:face_value_action_id, :equity_transaction_id], unique: true, name: :idx_face_value_transaction
  end
end
