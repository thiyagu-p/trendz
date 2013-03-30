class AddAppliedToActions < ActiveRecord::Migration
  def up
    add_column :bonus_actions, :applied, :boolean, default: false, null: false
    add_column :face_value_actions, :applied, :boolean, default: false, null:false
    add_column :dividend_actions, :applied, :boolean, default: false, null:false
  end

  def down
    remove_column :bonus_actions, :applied
    remove_column :face_value_actions, :applied
    remove_column :dividend_actions, :applied
  end
end
