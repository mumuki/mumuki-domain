class Mumuki::Domain::DiscussionStatus::Opened
  def self.reachable_statuses_for_initiator(discussion)
    if discussion.has_responses?
      [Mumuki::Domain::DiscussionStatus::PendingReview]
    else
      [Mumuki::Domain::DiscussionStatus::Closed]
    end
  end

  def self.reachable_statuses_for_moderator(discussion)
    if discussion.has_responses?
      [Mumuki::Domain::DiscussionStatus::Closed, Mumuki::Domain::DiscussionStatus::Solved]
    else
      [Mumuki::Domain::DiscussionStatus::Closed]
    end
  end

  def self.iconize
    {class: :warning, type: 'question-circle'}
  end

  def self.should_be_shown?(*)
    true
  end
end
