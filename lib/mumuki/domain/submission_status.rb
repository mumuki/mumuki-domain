module Mumuki::Domain::SubmissionStatus
  def group
    self
  end

  # Tells if a new, different submission should be tried.
  # True for `failed`, `errored` and `passed_with_warnings`
  def should_retry?
    false
  end

  def iconize
    group.iconize
  end

  def as_json(_options={})
    to_s
  end
end

require_relative 'submission_status/pending'
require_relative 'submission_status/running'
require_relative 'submission_status/passed'
require_relative 'submission_status/failed'
require_relative 'submission_status/errored'
require_relative 'submission_status/aborted'
require_relative 'submission_status/passed_with_warnings'
require_relative 'submission_status/manual_evaluation_pending'
