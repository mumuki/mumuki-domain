class RemoveDiscussions < ActiveRecord::Migration[7.0]
  def change
    drop_table :discussions
    drop_table :upvotes
    remove_column :messages, :from_moderator
    remove_column :messages, :discussion_id
  end
end
