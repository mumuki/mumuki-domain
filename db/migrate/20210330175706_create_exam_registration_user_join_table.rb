class CreateExamRegistrationUserJoinTable < ActiveRecord::Migration[5.1]
  def change
    create_join_table :exam_registrations, :users do |t|
      t.index :user_id
      t.index :exam_registration_id
    end
  end
end
