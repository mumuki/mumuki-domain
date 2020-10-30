class AddMedalToContent < ActiveRecord::Migration[5.1]
  def change
    add_reference :books, :medal, index: false
    add_reference :guides, :medal, index: false
    add_reference :topics, :medal, index: false
  end
end
