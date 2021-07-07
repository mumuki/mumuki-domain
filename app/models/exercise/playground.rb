class Playground < QueriableChallenge
  validate :ensure_queriable_language

  name_model_as Exercise

  def setup_query_assignment!(assignment, submission)
    assignment.running!
    assignment.persist_submission! submission
  end

  def save_query_results!(assignment)
    unless assignment.passed?
      assignment.passed!
      assignment.notify!
    end
  end

  private

  def ensure_queriable_language
    errors.add(:base, :language_not_queriable) unless queriable?
  end

end
