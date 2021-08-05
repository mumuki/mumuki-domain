class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :target, polymorphic: true, optional: true

  enum subject: %i(
    custom
    exam_registration_enabled
    exam_registration_approved
    exam_registration_rejected
    exam_results_available
    certificate_available)

  after_create :notify_via_email!

  scope :notified_users_ids_for, ->(target, organization=Organization.current) do
    where(target: target, organization: organization).pluck(:user_id)
  end

  def mark_as_read!
    update read: true
  end

  def notify_via_email!
    user.notify_via_email! self
  end

  def subject
    super || target.class.name.underscore
  end
end
