class Mumuki::Domain::DiscussionStatus::Solved
  def self.reachable_statuses_for_moderator(*)
    [Mumuki::Domain::DiscussionStatus::Opened, Mumuki::Domain::DiscussionStatus::Closed]
  end

  def self.iconize
    {class: :success, type: 'check-circle'}
  end

  def self.should_be_shown?(*)
    true
  end
end
