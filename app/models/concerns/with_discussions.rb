module WithDiscussions
  extend ActiveSupport::Concern

  included do
    has_many :discussions, as: :item, dependent: :destroy
    organic_on :discussions
  end

  def discuss!(user, discussion, organization = Organization.current)
    discussion.merge!(initiator_id: user.id, organization: organization)
    discussion.merge!(submission: submission_for(user)) if submission_for(user).present?
    created_discussion = discussions.create discussion
    user.subscribe_to! created_discussion
    created_discussion
  end

  def submission_for(_)
    nil
  end

  def try_solve_discussions(user)
    discussions.where(initiator: user).map(&:try_solve!)
  end
end
