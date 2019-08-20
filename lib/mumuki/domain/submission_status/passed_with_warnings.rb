module Mumuki::Domain::SubmissionStatus::PassedWithWarnings
  extend Mumuki::Domain::SubmissionStatus::Base

  def self.passed_with_warnings?
    true
  end

  def self.should_retry?
    true
  end

  def self.iconize
    {class: :warning, type: 'exclamation-circle'}
  end
end
