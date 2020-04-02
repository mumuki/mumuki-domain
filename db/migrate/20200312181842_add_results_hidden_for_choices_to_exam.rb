class AddResultsHiddenForChoicesToExam < ActiveRecord::Migration[5.1]
  def change
    add_column :exams, :results_hidden_for_choices, :boolean, default: false
  end
end
