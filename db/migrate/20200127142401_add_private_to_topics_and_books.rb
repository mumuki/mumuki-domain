class AddPrivateToTopicsAndBooks < ActiveRecord::Migration[5.1]
  def change
    add_column :topics, :private, :boolean, default: false
    add_column :books, :private, :boolean, default: false
  end
end
