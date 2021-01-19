class AddExamRegistrationToExam < ActiveRecord::Migration[5.1]
  def change
    add_reference :exams, :exam_registration, index: true
  end
end
