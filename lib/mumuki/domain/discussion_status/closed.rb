class Mumuki::Domain::DiscussionStatus::Closed
  def self.closed?
    true
  end

  def self.reachable_statuses_for_moderator(*)
    [Mumuki::Domain::DiscussionStatus::Opened, Mumuki::Domain::DiscussionStatus::Solved]
  end

  def self.iconize
    {class: :danger, type: 'times-circle'}
  end
end
