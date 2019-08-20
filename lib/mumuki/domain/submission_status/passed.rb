module Mumuki::Domain::SubmissionStatus::Passed
  extend Mumuki::Domain::SubmissionStatus::Base

  def self.passed?
    true
  end

  def self.iconize
    {class: :success, type: 'check-circle'}
  end
end
