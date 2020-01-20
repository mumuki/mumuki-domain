class AddParentToAssignments < ActiveRecord::Migration[5.1]
  def change
    add_reference :assignments, :parent
  end
end
