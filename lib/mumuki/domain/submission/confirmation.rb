class Mumuki::Domain::Submission::Confirmation < Mumuki::Domain::Submission::PersistentSubmission
  def content
    nil
  end

  def try_evaluate!(*)
    {status: Mumuki::Domain::SubmissionStatus::Passed, result: ''}
  end
end
