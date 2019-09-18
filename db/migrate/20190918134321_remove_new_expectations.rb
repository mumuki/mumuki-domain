class RemoveNewExpectations < ActiveRecord::Migration[5.1]
  def change
    remove_column :exercises, :new_expectations
  end
end
