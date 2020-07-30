class AddEmailVerificationFieldsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :email_verified, :boolean, default: false
    add_column :users, :verification_requested_date, :datetime
  end
end
