class AddUppercaseModeToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :uppercase_mode, :boolean
  end
end
