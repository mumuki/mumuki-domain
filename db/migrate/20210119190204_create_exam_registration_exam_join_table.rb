class CreateExamRegistrationExamJoinTable < ActiveRecord::Migration[5.1]
  def change
    create_join_table :exams, :exam_registrations do |t|
      t.index :exam_id
      t.index :exam_registration_id
    end
  end
end
