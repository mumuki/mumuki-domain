class AddSubmittedAtToAssignments < ActiveRecord::Migration[5.1]
  def change
    add_column :assignments, :submitted_at, :datetime
  end
end
