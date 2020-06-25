class AddPassingCriterionsToExam < ActiveRecord::Migration[5.1]
  def change
    add_column :exams, :passing_criterion_type, :integer, default: 0
    add_column :exams, :passing_criterion_value, :integer
  end
end
