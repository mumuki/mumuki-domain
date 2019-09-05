class Mumuki::Domain::DiscussionStatus::PendingReview
  def self.reachable_statuses_for_moderator(*)
    [Mumuki::Domain::DiscussionStatus::Opened, Mumuki::Domain::DiscussionStatus::Closed, Mumuki::Domain::DiscussionStatus::Solved]
  end

  def self.iconize
    {class: :info, type: 'hourglass'}
  end
end
