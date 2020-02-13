class AddVerifiedNamesToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :verified_first_name, :string
    add_column :users, :verified_last_name, :string
  end
end
