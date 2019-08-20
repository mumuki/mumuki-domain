module Mumuki::Domain::SubmissionStatus::Aborted
  extend Mumuki::Domain::SubmissionStatus::Base

  def self.aborted?
    true
  end

  def self.group
    Mumuki::Domain::SubmissionStatus::Failed
  end
end
