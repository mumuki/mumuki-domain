module Mumuki::Domain::SubmissionStatus::ManualEvaluationPending


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
