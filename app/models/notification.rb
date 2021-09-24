class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :target, polymorphic: true, optional: true

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
    target_type.constantize.subject
  end

  class << self
    def create_and_notify_via_email!(args)
      create!(args).tap(&:notify_via_email!)
    end
  end
end
