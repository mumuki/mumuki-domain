class AddIgnoredNotificationsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :ignored_notifications, :text
  end
end
