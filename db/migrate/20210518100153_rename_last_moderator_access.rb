class RenameLastModeratorAccess < ActiveRecord::Migration[5.1]
  def change
    rename_column :discussions, :last_moderator_access_by_id, :responsible_moderator_by_id
    rename_column :discussions, :last_moderator_access_at, :responsible_moderator_at
  end
end
