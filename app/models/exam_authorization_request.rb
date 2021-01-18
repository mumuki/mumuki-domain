class ExamAuthorizationRequest < ApplicationRecord
  belongs_to :exam
  belongs_to :user
  belongs_to :organization

  enum status: %i[pending approved rejected]

  before_save :set_default_status!
  after_update :notify_user!

  def set_default_status!
    self.status ||= :pending
  end

  def try_authorize!
    exam.authorize! user if approved?
  end

  def notify_user!
    Notification.create! organization: organization, user: user, target: self if saved_change_to_status?
  end
end
