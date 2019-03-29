class AddSessionIdToExamAuthorization < ActiveRecord::Migration[5.1]
  def change
    add_column :exam_authorizations, :session_id, :string
  end
end
