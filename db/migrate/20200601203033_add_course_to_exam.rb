class AddCourseToExam < ActiveRecord::Migration[5.1]
  def change
    add_reference :exams, :course, foreign_key: true
  end
end
