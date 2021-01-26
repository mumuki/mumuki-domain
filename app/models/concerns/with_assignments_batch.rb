# WithAssignmentsBatch mirrors the WithAssignment mixin
# but implements operations in batches, so that they outperform
# their counterparts
module WithAssignmentsBatch
  extend ActiveSupport::Concern

  def find_assignments_for(user, _organization = Organization.current)
    exercises = self.exercises
    ActiveRecord::Associations::Preloader.new.preload(exercises, :assignments, Assignment.where(submitter: user))

    if block_given?
      exercises.map { |it| yield it.assignments.first, it }
    else
      exercises.map { |it| it.assignments.first }
    end
  end

  def statuses_for(user, organization = Organization.current)
    find_assignments_for user, organization do |it|
      it&.status || Mumuki::Domain::Status::Submission::Pending
    end
  end

  def assignments_for(user, organization = Organization.current)
    find_assignments_for user, organization do |it, exercise|
      it || user.build_assignment(exercise, organization)
    end
  end
end
