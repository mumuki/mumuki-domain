class AddAssignmentIdToMessage < ActiveRecord::Migration[5.1]
  def change
    add_reference :messages, :assignment, index: true
  end
end
