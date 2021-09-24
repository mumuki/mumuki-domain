class CustomNotification < ApplicationRecord

  belongs_to :organization

  has_and_belongs_to_many :users
  has_many :notifications, as: :target

  validates :title, :body_html, presence: true

  def notify_users_to_add!(uids)
    uids.each do |uid|
      Mumukit::Nuntius.notify_job! 'CustomNotificationUserAdded', custom_notification_id: id, uid: uid
    end
  end

  def add_user_and_notify_via_email!(uid)
    add_user! User.locate! uid
  end

  private

  def add_user!(user)
    return if users.include? user
    transaction do
      users << user
      Notification.create_and_notify_via_email!(organization: organization, user: user, target: self)
    end
  end

  class << self
    def subject
      :custom_notification
    end

    def add_user_and_notify_via_email!(custom_notification_id, uid)
      find(custom_notification_id).add_user_and_notify_via_email!(uid)
    end

    def notify_users_to_add!(custom_notification_id, uids)
      find(custom_notification_id).notify_users_to_add!(uids)
    end
  end

end
