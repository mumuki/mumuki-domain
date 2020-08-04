module WithDiscussions
  extend ActiveSupport::Concern

  included do
    has_many :discussions, as: :item, dependent: :destroy
    organic_on :discussions
  end

  def discuss!(user, discussion, organization = Organization.current)
    new_discussion_for(user, discussion, organization).tap &:save!
  end

  def submission_for(_)
    nil
  end

  def try_solve_discussions!(user)
    discussions.where(initiator: user).map(&:try_solve!)
  end

  def new_discussion_for(user, discussion_h = {}, organization = Organization.current)
    discussion_h.merge!(initiator_id: user.id, organization: organization)
    discussion_h.merge!(submission: submission_for(user)) if submission_for(user).present?
    discussions.new discussion_h
  end

  def current_discussion_for(user)
    discussions.find_by(initiator: user, status: Mumuki::Domain::Status::Discussion::Opened)
  end

end
