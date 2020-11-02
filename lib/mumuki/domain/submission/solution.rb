class Mumuki::Domain::Submission::Solution < Mumuki::Domain::Submission::PersistentSubmission
  attr_accessor :content

  def dry_run!(assignment, evaluation)
    evaluation.evaluate! assignment, self
  end

  def try_evaluate!(assignment)
    assignment
      .run_tests!({client_result: client_result}.compact.merge(content: content))
      .except(:response_type)
  end
end
