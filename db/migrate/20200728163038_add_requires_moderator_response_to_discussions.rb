class AddRequiresModeratorResponseToDiscussions < ActiveRecord::Migration[5.1]
  def change
    add_column :discussions, :requires_moderator_response, :boolean, default: true
  end
end
