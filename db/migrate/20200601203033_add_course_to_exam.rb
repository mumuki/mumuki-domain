class AddCourseToExam < ActiveRecord::Migration[5.1]
  def change
    add_reference :exams, :course
  end
end
