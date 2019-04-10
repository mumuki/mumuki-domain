module WithDiscussionCreation
  extend ActiveSupport::Concern

  included do
    has_many :discussions, foreign_key: 'initiator_id'
    include WithDiscussionCreation::Subscription
    include WithDiscussionCreation::Upvote
    organic_on :discussions
  end
end
