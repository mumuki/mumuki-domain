class AddMessagesCountToDiscussion < ActiveRecord::Migration[5.1]
  def change
    add_column :discussions, :messages_count, :integer, default: 0
    add_column :discussions, :useful_messages_count, :integer, default: 0
    add_column :discussions, :last_initiator_message_at, :datetime
    add_column :discussions, :last_moderator_message_at, :datetime
  end
end
