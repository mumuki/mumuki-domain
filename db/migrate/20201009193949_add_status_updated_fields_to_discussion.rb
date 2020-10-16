class AddStatusUpdatedFieldsToDiscussion < ActiveRecord::Migration[5.1]
  def change
    add_reference :discussions, :status_updated_by, index: true
    add_column :discussions, :status_updated_at, :datetime
  end
end
