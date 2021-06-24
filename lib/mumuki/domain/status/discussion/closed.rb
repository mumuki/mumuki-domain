module Mumuki::Domain::Status::Discussion::Closed
  extend Mumuki::Domain::Status::Discussion

  def self.closed?
    true
  end

  def self.reachable_statuses_for_moderator(*)
    [Mumuki::Domain::Status::Discussion::Opened, Mumuki::Domain::Status::Discussion::Solved]
  end

  def self.iconize
    {class: :danger, type: 'times-circle'}
  end

  def self.requires_attention_for?(_)
    false
  end
end
