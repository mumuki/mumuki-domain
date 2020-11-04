module Mumuki::Domain
  class IncognitoClass

    def incognito?
      true
    end

    # ============
    # Permissions
    # ============

    def ensure_enabled!
    end

    def has_student_granted_organizations?
      false
    end

    def teacher_here?
      false
    end

    def teacher_of?(*)
      false
    end

    def profile_completed?
      true
    end

    def writer?
      false
    end

    def moderator_here?
      false
    end

    def can_discuss_here?
      false
    end

    def can_discuss_in?(*)
      false
    end

    def can_access_teacher_info_in?(*)
      false
    end

    def current_immersive_context_at(_)
      nil
    end

    def immersive_organizations_at(_)
      []
    end

    def any_granted_roles
      []
    end

    # ========
    # Terms
    # ========

    def accepted_profile_terms?
      true
    end

    def accepted_forum_terms?
      true
    end

    def has_accepted?(term)
      false
    end

    # ========
    # Visiting
    # ========

    def visit!(*)
    end

    # ========
    # Progress
    # ========

    def next_exercise_at(guide)
      guide.exercises.first
    end

    # def completed_containers_with_lookahead(*)
    #   raise 'Unsupported operation. Userless mode and progressive display modes are incompatible'
    # end

    def progress_at(content, organization)
      Indicator.new content: content, organization: organization
    end

    def build_assignment(exercise, organization)
      Assignment.new exercise: exercise, organization: organization, submitter: self
    end

    def pending_siblings_at(content)
      []
    end

    # ============
    # ActiveRecord
    # ============

    def id
      '<incognito>'
    end

    def is_a?(other)
      other.is_a?(Class) && other.name == 'User' || super
    end

    def _read_attribute(key)
      return id if key == 'id'
      raise "unknown attribute #{key}"
    end

    def new_record?
      false
    end

    def self.primary_key
      'id'
    end

    # ==========
    # Evaluation
    # ==========

    def interpolations
      []
    end

    def run_submission!(submission, assignment, evaluation)
      results = submission.dry_run! assignment, evaluation
      assignment.assign_attributes results
      results
    end
  end

  Incognito = IncognitoClass.new
end
