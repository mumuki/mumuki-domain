class AddPurposeToExercises < ActiveRecord::Migration[5.1]
  def change
    add_column :exercises, :purpose, :integer, :default => 0
  end
end
