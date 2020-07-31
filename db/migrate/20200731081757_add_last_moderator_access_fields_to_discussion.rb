class AddLastModeratorAccessFieldsToDiscussion < ActiveRecord::Migration[5.1]
  def change
    add_column :discussions, :last_moderator_access_by_id, :string
    add_column :discussions, :last_moderator_access_at, :datetime
  end
end
