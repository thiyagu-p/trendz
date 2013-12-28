class AddCorporateActionOnPortfolioTracker < ActiveRecord::Migration
  def change
    create_join_table :equity_transaction, :bonus_action, table_name: :bonus_transactions

    add_foreign_key(:bonus_transactions, :equity_transactions)
    add_foreign_key(:bonus_transactions, :bonus_actions)

    create_join_table :equity_transaction, :face_value_action, table_name: :face_value_transactions

    add_foreign_key(:face_value_transactions, :face_value_actions)
    add_foreign_key(:face_value_transactions, :equity_transactions)
  end
end
