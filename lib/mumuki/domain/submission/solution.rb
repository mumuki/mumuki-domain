class Mumuki::Domain::Submission::Solution < Mumuki::Domain::Submission::PersistentSubmission
  attr_accessor :content

  def try_evaluate!(assignment)
    assignment.run_tests!(content: content, client_result: client_result).except(:response_type)
  end
end
