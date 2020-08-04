module WithDiscussionCreation
  extend ActiveSupport::Concern

  included do
    has_many :discussions, foreign_key: 'initiator_id'
    include WithDiscussionCreation::Subscription
    include WithDiscussionCreation::Upvote
    organic_on :discussions
  end

  def discussed_on_current_assignment?(debatable)
    discussion = debatable.current_discussion_for self
    assignment = debatable.assignment_for self
    discussion.present? && assignment.submission_id == discussion.submission_id
  end
end
