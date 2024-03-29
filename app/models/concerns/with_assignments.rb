module WithAssignments
  extend ActiveSupport::Concern

  # TODO we must avoid _for(user) methods when they
  # are hidden the assignment object, since an assignment already encapsulates
  # the exercise-user pair, and many times they impose a performance hit,
  # since in the normal scenario the assignment object already exists

  included do
    has_many :assignments, dependent: :destroy
  end

  def messages_for(user)
    assignment_for(user).messages
  end

  def has_messages_for?(user)
    messages_for(user).present?
  end

  # TODO: When the organization is used in this one, please change guide.pending_exercises
  def find_assignment_for(user, organization)
    assignments.find_by(submitter: user, organization: organization)
  end

  def status_for(user)
    assignment_for(user).status if user
  end

  def assignment_for(user, organization=Organization.current)
    find_assignment_for(user, organization) || user.build_assignment(self, organization)
  end

  def has_progress_for?(user, organization)
    user.present? && find_assignment_for(user, organization).present?
  end


end
