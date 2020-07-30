class AddTrustedForForumToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :trusted_for_forum, :boolean, default: false
  end
end
