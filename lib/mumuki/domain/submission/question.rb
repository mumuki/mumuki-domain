class Mumuki::Domain::Submission::Question < Mumuki::Domain::Submission::Base
  def run!(assignment, evaluation)
    return [assignment, nil] unless assignment.new_record?
    super
  end

  def save_submission!(assignment)
  end

  def try_evaluate!(*)
    {status: :pending, result: nil}
  end
end
