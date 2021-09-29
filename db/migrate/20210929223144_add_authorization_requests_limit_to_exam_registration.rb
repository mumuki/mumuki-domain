class AddAuthorizationRequestsLimitToExamRegistration < ActiveRecord::Migration[5.1]
  def change
    add_column :exam_registrations, :authorization_requests_limit, :integer
  end
end
