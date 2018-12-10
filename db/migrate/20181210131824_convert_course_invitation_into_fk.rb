class ConvertCourseInvitationIntoFk < ActiveRecord::Migration[5.1]
  def change
    remove_column :invitations, :course
    add_reference :invitations, :course, index: true
  end
end
