class ReferenceSenderViaIdInMessages < ActiveRecord::Migration[5.1]
  def change
    add_reference :messages, :sender, index: true
  end
end
