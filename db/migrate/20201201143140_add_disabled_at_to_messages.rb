class AddDisabledAtToMessages < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :disabled_at, :datetime
    add_reference :messages, :disabled_by
    add_index :messages, :disabled_at
  end
end
