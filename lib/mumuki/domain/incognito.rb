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

    def ex_student_of?(*)
      false
    end

    def ex_student_here?
      false
    end

    def student_of?(*)
      false
    end

    def student_here?
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

    def current_immersive_context_and_content_at(_)
      [nil, nil]
    end

    def immersive_organizations_with_content_at(_, _ = nil)
      []
    end

    def immersive_organizations_at(_, _ = nil)
      []
    end

    def any_granted_roles
      []
    end

    # ========
    # Terms
    # ========

    # It avoids role terms acceptance redirections
    def has_role_terms_to_accept?
      false
    end

    # It makes terms UI to be shown as if no terms were accepted
    # It does not force any term to be accepted though
    def has_accepted?(term)
      false
    end

    # ========
    # Visiting
    # ========

    def visit!(*)
    end

    def currently_in_exam?
      false
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
      Assignment.build_for(self, exercise, organization)
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
