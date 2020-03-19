class CreateAccessRules < ActiveRecord::Migration[5.1]
  def change
    create_table :access_rules do |t|
      t.references :chapter, index: true
      t.references :owner, polymorphic: true, index: true

      t.boolean :active, default: true, null: false
      t.integer :action, default: 0, null: false

      t.datetime :date, null: true
      t.string :role, null: true

      t.string :type, null: false

      t.timestamps
    end
  end
end
