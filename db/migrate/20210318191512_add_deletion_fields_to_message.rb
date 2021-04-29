class AddDeletionFieldsToMessage < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :deletion_motive, :integer
    add_column :messages, :deleted_at, :datetime
    add_reference :messages, :deleted_by, index: true
  end
end
