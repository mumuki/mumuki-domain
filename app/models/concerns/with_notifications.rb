module WithNotifications
  extend ActiveSupport::Concern

  def unread_messages
    messages_in_organization.where read: false
  end

  def unread_notifications
    all = notifications_in_organization.where(read: false) + unread_messages
    all.sort_by(&:created_at).reverse
  end

  def read_notification!(target)
    notifications.find_by(target: target)&.mark_as_read!
  end
end
