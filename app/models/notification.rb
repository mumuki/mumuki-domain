class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :target, polymorphic: true, optional: true

  enum subject: %i(
    custom
    exam_authorization_request_updated
    exam_registration)

  scope :notified_users_ids_for, ->(target, organization=Organization.current) do
    where(target: target, organization: organization).pluck(:user_id)
  end

  def mark_as_read!
    update read: true
  end

  def enqueue!
    Mumukit::Nuntius.notify_job! 'SendNotificationEmail', { notification_id: id }
  end

  def notify_via_email!
    user.notify_via_email! self
  end

  class << self
    def create_and_enqueue!(args)
      create!(args).tap(&:enqueue!)
    end

    def create_and_notify_via_email!(args)
      create!(args).tap(&:notify_via_email!)
    end

    def notify_via_email!(notification_id)
      find(notification_id).notify_via_email!
    end

    def create_massive_notifications_for!(notification_params, uids)
      User.where(uid: uids).each do |user|
        create_and_enqueue! notification_params.merge(user: user)
      end
    end
  end
end
