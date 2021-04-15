class AddOfflineTestToExercise < ActiveRecord::Migration[5.1]
  def change
    add_column :exercises, :offline_test, :text
  end
end
