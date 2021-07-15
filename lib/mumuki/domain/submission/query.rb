class Mumuki::Domain::Submission::Query < Mumuki::Domain::Submission::ConsoleSubmission
  attr_accessor :query, :cookie, :content

  def try_evaluate_query!(assignment)
    assignment.run_query!(content: content, query: query, cookie: cookie)
  end

  def save_submission!(assignment)
    assignment.exercise.save_query_submission!(assignment, self)
    super
  end

  def save_results!(_results, assignment)
    assignment.exercise.save_query_results!(assignment)
  end

  def notify_results!(*)
  end
end
