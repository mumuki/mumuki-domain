class AddPolymorphicAvatarsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :avatar_type, :string, default: 'Avatar'
    add_index :users, [:avatar_type, :avatar_id]
  end
end
