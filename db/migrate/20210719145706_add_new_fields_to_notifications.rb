class AddNewFieldsToNotifications < ActiveRecord::Migration[5.1]
  def change
    add_column :notifications, :subject, :integer
    add_column :notifications, :custom_title, :text
    add_column :notifications, :custom_content_plain_text, :text
    add_column :notifications, :custom_content_html, :text
  end
end
