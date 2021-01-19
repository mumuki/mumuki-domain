class CreateExamAuthorizationRequest < ActiveRecord::Migration[5.1]
  def change
    create_table :exam_authorization_requests do |t|
      t.integer :status, default: 0
      t.references :exam, index: true
      t.references :exam_registration, index: true
      t.references :user, index: true
      t.references :organization, index: true

      t.timestamps
    end
  end
end
