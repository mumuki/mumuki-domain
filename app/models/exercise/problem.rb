class Problem < QueriableChallenge
  include WithExpectations,
          WithEditor,
          Solvable

  markdown_on :corollary

  validate :ensure_evaluation_criteria

  serialize :offline_test, Hash

  name_model_as Exercise

  def setup_query_assignment!(assignment)
  end

  def save_query_results!(assignment)
  end

  def reset!
    super
    self.test = nil
    self.expectations = []
  end

  def expectations
    own_expectations + guide_expectations
  end

  def custom_expectations
    "#{own_custom_expectations}\n#{guide_custom_expectations}"
  end

  def guide_expectations
    guide.expectations
  end

  def guide_custom_expectations
    guide.custom_expectations
  end

  def evaluation_criteria?
    manual_evaluation? || expectations? || test.present?
  end

  def expectations?
    own_expectations.present? || own_custom_expectations.present?
  end

  private

  def ensure_evaluation_criteria
    errors.add :base, :evaluation_criteria_required unless evaluation_criteria?
  end
end
