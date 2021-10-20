class AddFromModeratorToMessages < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :from_moderator, :boolean
  end
end
