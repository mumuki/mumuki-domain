module Mumuki::Domain::SubmissionStatus::ManualEvaluationPending
  extend Mumuki::Domain::SubmissionStatus::Base

  def self.manual_evaluation_pending?
    true
  end

  def self.group
    Mumuki::Domain::SubmissionStatus::Passed
  end

  def self.iconize
    {class: :info, type: 'clock-o'}
  end
end
