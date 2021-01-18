class CreateNotification < ActiveRecord::Migration[5.1]
  def change
    create_table :notifications do |t|
      t.integer :priority, default: 100
      t.boolean :read, default: false
      t.references :target, polymorphic: true
      t.references :user, index: true
      t.references :organization, index: true

      t.timestamps
    end
  end
end
