class CreateExamRegistrations < ActiveRecord::Migration[5.1]
  def change
    create_table :exam_registrations do |t|
      t.string :description
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.integer :authorization_criterion_type, default: 0
      t.integer :authorization_criterion_value
      t.references :organization, index: true

      t.timestamps
    end
  end
end
