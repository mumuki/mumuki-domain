class AddNotActuallyAQuestionFieldToMessages < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :not_actually_a_question, :boolean, default: false
  end
end
