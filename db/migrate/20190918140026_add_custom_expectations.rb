class AddCustomExpectations < ActiveRecord::Migration[5.1]
  def change
    add_column :exercises, :custom_expectations, :text
    add_column :guides, :custom_expectations, :text
  end
end
