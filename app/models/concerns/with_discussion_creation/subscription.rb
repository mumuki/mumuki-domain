module WithDiscussionCreation::Subscription
  extend ActiveSupport::Concern

  included do
    has_many :subscriptions
    has_many :watched_discussions, -> { order(created_at: :desc) }, through: :subscriptions, source: :discussion
    organic_on :watched_discussions
  end

  def subscriptions_in_organization
    subscriptions.where(discussion: Organization.current.discussions)
  end

  def subscribed_to?(discussion)
    discussion.subscription_for(self).present?
  end

  def subscribe_to!(discussion)
    watched_discussions << discussion unless subscribed_to? discussion
  end

  def unsubscribe_to!(discussion)
    watched_discussions.delete(discussion)
  end

  def toggle_subscription!(discussion)
    if subscribed_to?(discussion)
      unsubscribe_to!(discussion)
    else
      subscribe_to!(discussion)
    end
  end

  def unread_discussions
    subscriptions_in_organization.where(read: false).map(&:discussion)
  end
end
