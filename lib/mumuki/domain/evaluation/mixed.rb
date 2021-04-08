class Mumuki::Domain::Evaluation::Mixed < Mumuki::Domain::Evaluation::Manual
  def evaluate!(assignment, submission)
    evaluation = submission.evaluate! assignment
    if evaluation[:status].passed?
      super
    elsif evaluation[:status].passed_with_warnings?
      evaluation.merge(status: Mumuki::Domain::Status::Submission::Failed)
    else
      evaluation
    end
  end
end