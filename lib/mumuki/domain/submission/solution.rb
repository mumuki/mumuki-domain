class Mumuki::Domain::Submission::Solution < Mumuki::Domain::Submission::PersistentSubmission
  attr_accessor :content

  def try_evaluate!(assignment)
    assignment
      .run_tests!({client_result: client_result}.compact.merge(content: content))
      .except(:response_type)
  end
end
