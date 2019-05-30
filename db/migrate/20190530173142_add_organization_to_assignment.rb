class AddOrganizationToAssignment < ActiveRecord::Migration[5.1]
  def change
    add_reference :assignments, :organization, index: true
  end
end
