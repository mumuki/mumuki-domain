class Mumuki::Domain::Evaluation::Manual
  def evaluate!(*)
    {status: Mumuki::Domain::SubmissionStatus::ManualEvaluationPending, result: ''}
  end
end
