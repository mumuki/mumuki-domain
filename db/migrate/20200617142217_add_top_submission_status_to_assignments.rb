class AddTopSubmissionStatusToAssignments < ActiveRecord::Migration[5.1]
  def change
    add_column :assignments, :top_submission_status, :integer
  end
end
