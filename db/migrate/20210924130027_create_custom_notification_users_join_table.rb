class CreateCustomNotificationUsersJoinTable < ActiveRecord::Migration[5.1]
  def change
    create_join_table :custom_notifications, :users do |t|
      t.index :user_id
      t.index :custom_notification_id
    end
  end
end
