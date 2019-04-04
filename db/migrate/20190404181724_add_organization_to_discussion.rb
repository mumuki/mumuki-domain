class AddOrganizationToDiscussion < ActiveRecord::Migration[5.1]
  def change
    add_reference :discussions, :organization, index: true
  end
end
