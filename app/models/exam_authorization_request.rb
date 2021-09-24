class ExamAuthorizationRequest < ApplicationRecord
  include TerminalNavigation

  belongs_to :exam
  belongs_to :user
  belongs_to :organization
  belongs_to :exam_registration

  enum status: %i(pending approved rejected)

  after_update :notify_user!

  def try_authorize!
    exam.authorize! user if approved?
  end

  def name
    exam_registration.description
  end

  def icon
    case status.to_sym
    when :pending
      { class: 'hourglass', type: 'info' }
    when :approved
      { class: 'check-circle', type: 'success' }
    when :rejected
      { class: 'times-circle', type: 'danger' }
    end
  end

  private

  def notify_user!
    Notification.create_and_notify_via_email!(organization: organization, user: user, target: self) if saved_change_to_status?
  end

  class << self
    def subject
      :exam_authorization_request_updated
    end
  end
end
