module Mumuki::Domain
  class NilUserClass
    def id
      '<none>'
    end

    def ensure_enabled!
    end

    def has_student_granted_organizations?
      false
    end

    def teacher_here?
      false
    end

    def profile_completed?
      true
    end

    def visit!(*)
    end

    def teacher_of?(*)
      false
    end

    def completed_containers_with_lookahead(*)
      raise 'Unsupported operation. Userless mode and progressive display modes are incompatible'
    end

    def progress_at(content, organization)
      Indicator.new content: content, organization: organization
    end

    def profile_picture
      "user_shape.png"
    end

    def writer?
      false
    end

    def moderator_here?
      false
    end

    def watched_discussions
      []
    end

    def assignments
      []
    end

    def build_assignment(exercise, organization)
      Assignment.new exercise: exercise, organization: organization, submitter: self
    end

    def is_a?(other)
      other.is_a?(Class) && other.name == 'User' || super
    end

    def _read_attribute(key)
      return id if key == 'id'
      raise "unknown attribute #{key}"
    end

    def interpolations
      []
    end

    def pending_siblings_at(content)
      []
    end

    def run_submission!(submission, assignment, evaluation)
      results = submission.dry_run! assignment, evaluation
      assignment.assign_attributes results
      results
    end

    def self.primary_key
      'id'
    end


  end

  NilUser = NilUserClass.new
end
