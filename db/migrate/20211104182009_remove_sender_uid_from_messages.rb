class RemoveSenderUidFromMessages < ActiveRecord::Migration[5.1]
  def change
    remove_column :messages, :sender, :string
  end
end
