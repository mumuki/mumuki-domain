class AddApprobedByAndAtToMessage < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :approved_at, :datetime
    add_reference :messages, :approved_by, index: true
  end
end
