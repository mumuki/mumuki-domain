class RemoveChoiceValuesFromExercises < ActiveRecord::Migration[5.1]
  def change
    remove_column :exercises, :choice_values, :string, array: true, default: [], null: false
  end
end
