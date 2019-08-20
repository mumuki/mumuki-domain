module Mumuki::Domain::SubmissionStatus::Errored
  extend Mumuki::Domain::SubmissionStatus::Base

  def self.errored?
    true
  end

  def self.should_retry?
    true
  end

  def self.group
    Mumuki::Domain::SubmissionStatus::Failed
  end

  def self.iconize
    {class: :broken, type: 'minus-circle'}
  end
end
