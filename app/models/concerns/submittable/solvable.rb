module Solvable
  def submit_solution!(user, submission_attributes={})
    assignment, _ = find_assignment_and_submit! user, solution_for(submission_attributes)
    try_solve_discussions(user) if assignment.solved?
    assignment
  end

  def run_tests!(params)
    language.run_tests!(params.merge(locale: locale, expectations: expectations, custom_expectations: custom_expectations))
  end

  def solution_for(submission_attributes)
    submission_attributes[:content].to_mumuki_solution(language)
  end
end

class NilClass
  def to_mumuki_solution(language)
    Mumuki::Domain::Submission::Solution.new
  end
end

class String
  def to_mumuki_solution(language)
    Mumuki::Domain::Submission::Solution.new content: normalize_whitespaces
  end
end

class Hash
  def to_mumuki_solution(language)
    language
      .directives_sections
      .join(self)
      .to_mumuki_solution(language)
  end
end
