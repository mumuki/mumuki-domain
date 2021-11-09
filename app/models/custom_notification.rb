class CustomNotification < ApplicationRecord

  belongs_to :organization

  validates :title, :body_html, presence: true

  alias_attribute :description, :title

  def processed?(user)
    Notification.exists?(organization: organization, user: user, target: self)
  end

  def process!(user)
    Notification.create_and_notify_via_email!(organization: organization, user: user, target: self)
  end

  private

  class << self
    def subject
      :custom_notification
    end
  end
end
