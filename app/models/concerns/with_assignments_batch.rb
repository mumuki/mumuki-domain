# WithAssignmentsBatch mirrors the WithAssignment mixin
# but implements operations in batches, so that they outperform
# their counterparts
module WithAssignmentsBatch
  extend ActiveSupport::Concern

  def find_assignments_for(user, _organization = Organization.current, &block)
    block = block_given? ? block : lambda { |it, _e| it }

    return exercises.map { |it| block.call nil, it  } unless user

    pairs = exercises.map { |it| [it.id, [nil, it]] }.to_h
    Assignment.where(submitter: user, exercise: exercises).each do |it|
      pairs[it.exercise_id][0] = it
    end

    pairs.values.map { |assignment, exercise| block.call assignment, exercise }
  end

  def statuses_for(user, organization = Organization.current)
    find_assignments_for user, organization do |it|
      it&.status || Mumuki::Domain::Status::Submission::Pending
    end
  end

  def assignments_for(user, organization = Organization.current)
    find_assignments_for user, organization do |it, exercise|
      it || Assignment.build_for(user, exercise, organization)
    end
  end
end
