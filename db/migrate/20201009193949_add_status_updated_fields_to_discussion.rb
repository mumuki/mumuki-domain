class AddStatusUpdatedFieldsToDiscussion < ActiveRecord::Migration[5.1]
  def change
    add_column :discussions, :status_updated_by_id, :string
    add_column :discussions, :status_updated_at, :datetime
  end
end
