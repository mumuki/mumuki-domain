class AddMessagesCountToDiscussion < ActiveRecord::Migration[5.1]
  def change
    add_column :discussions, :messages_count, :integer, default: 0
    add_column :discussions, :validated_messages_count, :integer, default: 0
  end
end
