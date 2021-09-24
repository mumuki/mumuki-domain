class CreateCustomNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :custom_notifications do |t|
      t.string :title
      t.text :body_html
      t.text :custom_html
      t.references :organization, index: true

      t.timestamps
    end
  end
end
