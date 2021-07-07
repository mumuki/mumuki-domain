class Problem < QueriableChallenge
  include WithExpectations,
          WithEditor,
          Solvable

  markdown_on :corollary

  validate :ensure_evaluation_criteria

  name_model_as Exercise

  def setup_query_assignment!(_assignment, _submission)
  end

  def save_query_results!(assignment)
  end

  def reset!
    super
    self.test = nil
    self.expectations = []
  end

  alias_method :own_expectations, :expectations
  alias_method :own_custom_expectations, :custom_expectations

  def expectations
    own_expectations + guide.expectations
  end

  def custom_expectations
    "#{own_custom_expectations}\n#{guide.custom_expectations}"
  end

  def evaluation_criteria?
    manual_evaluation? || automated_evaluation?
  end

  def mixed_evaluation?
    manual_evaluation? && automated_evaluation?
  end

  def automated_evaluation?
    expectations? || test.present?
  end

  def expectations?
    own_expectations.present? || own_custom_expectations.present?
  end

  def evaluation_class
    if mixed_evaluation?
      Mumuki::Domain::Evaluation::Mixed
    elsif manual_evaluation?
      Mumuki::Domain::Evaluation::Manual
    else
      Mumuki::Domain::Evaluation::Automated
    end
  end

  # Sets the layout. This method accepts input_kids as a synonym of input_primary
  # for historical reasons
  def layout=(layout)
    self[:layout] = layout.like?(:input_kids) ? :input_primary : layout
  end

  private

  def ensure_evaluation_criteria
    errors.add :base, :evaluation_criteria_required unless evaluation_criteria?
  end
end
