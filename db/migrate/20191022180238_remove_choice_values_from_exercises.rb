class RemoveChoiceValuesFromExercises < ActiveRecord::Migration[5.1]
  def change
    remove_column :exercises, :choice_values, :string
  end
end
