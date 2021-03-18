class AddDeleteAccountTokenToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :delete_account_token, :string
    add_column :users, :delete_account_token_expiration_date, :datetime
  end
end
