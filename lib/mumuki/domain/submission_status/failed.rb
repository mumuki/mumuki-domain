module Mumuki::Domain::SubmissionStatus::Failed
  def self.failed?
    true
  end

  def self.should_retry?
    true
  end

  def self.iconize
    {class: :danger, type: 'times-circle'}
  end
end
