class ExamAuthorizationRequest < ApplicationRecord
  belongs_to :exam
  belongs_to :user
  belongs_to :organization

  enum status: %i(pending approved rejected)

  after_update :notify_user!

  def try_authorize!
    exam.authorize! user if approved?
  end

  private

  def notify_user!
    Notification.create! organization: organization, user: user, target: self if saved_change_to_status?
  end
end
