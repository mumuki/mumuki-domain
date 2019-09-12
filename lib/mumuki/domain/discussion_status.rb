module Mumuki::Domain::DiscussionStatus
  ENUM = [:opened, :closed, :solved, :pending_review]

  def allowed_for?(*)
    true
  end

  def reachable_statuses_for_moderator(*)
    []
  end

  def reachable_statuses_for_initiator(*)
    []
  end

  def should_be_shown?(count, user)
    count > 0 || user&.moderator_here?
  end

  def reachable_statuses_for(user, discussion)
    if user.moderator_here?
      reachable_statuses_for_moderator(discussion)
    else
      reachable_statuses_for_initiator(discussion)
    end
  end

  def allowed_statuses_for(user, discussion)
    constants(false).select { |it| it.allowed_for?(user, discussion) }
  end
end

require_relative 'discussion_status/opened'
require_relative 'discussion_status/closed'
require_relative 'discussion_status/pending_review'
require_relative 'discussion_status/solved'

