module Mumuki::Domain::SubmissionStatus::Passed
  def self.passed?
    true
  end

  def self.iconize
    {class: :success, type: 'check-circle'}
  end
end
