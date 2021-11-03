module Mumuki::Domain::Status::Submission
  include Mumuki::Domain::Status
end

require_relative './pending'
require_relative './running'
require_relative './passed'
require_relative './failed'
require_relative './errored'
require_relative './aborted'
require_relative './passed_with_warnings'
require_relative './manual_evaluation_pending'
require_relative './skipped'

module Mumuki::Domain::Status::Submission
  STATUSES = [Pending, Running, Passed, Failed, Errored, Aborted, PassedWithWarnings, ManualEvaluationPending, Skipped]

  test_selectors.each do |selector|
    define_method(selector) { false }
  end

  def group
    self
  end

  def should_retry?
    false
  end

  def iconize
    group.iconize
  end

  def completed?
    solved?
  end

  def solved?
    passed? || skipped?
  end

  def improved_by?(status)
    self.exp_given < status.exp_given
  end

  def exp_given
    0
  end
end
