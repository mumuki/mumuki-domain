module WithNotifications
  extend ActiveSupport::Concern

  def unread_messages
    messages_in_organization.where read: false
  end

  def unread_notifications
    # TODO: message and discussion should trigger a notification instead of being one
    all = notifications_in_organization.where(read: false) + unread_messages + unread_discussions
    all.sort_by(&:created_at).reverse
  end

  def read_notification!(target)
    notifications.find_by(target: target)&.mark_as_read!
  end
end
