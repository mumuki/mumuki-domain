class CustomNotification < ApplicationRecord

  belongs_to :organization

  has_and_belongs_to_many :users
  has_one :massive_job, as: :target
  has_many :notifications, as: :target

  validates :title, :body_html, presence: true

  alias_attribute :description, :title

  def processed?(user)
    users.include? user
  end

  def process!(user)
    transaction do
      users << user
      Notification.create_and_notify_via_email!(organization: organization, user: user, target: self)
    end
  end

  private

  class << self
    def subject
      :custom_notification
    end
  end
end
