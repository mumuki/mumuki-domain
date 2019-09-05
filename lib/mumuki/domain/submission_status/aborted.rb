module Mumuki::Domain::SubmissionStatus::Aborted
  def self.aborted?
    true
  end

  def self.group
    Mumuki::Domain::SubmissionStatus::Failed
  end
end
