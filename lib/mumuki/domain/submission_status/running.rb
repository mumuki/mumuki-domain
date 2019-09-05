module Mumuki::Domain::SubmissionStatus::Running
  def self.running?
    true
  end

  def self.group
    Mumuki::Domain::SubmissionStatus::Pending
  end

  def self.iconize
    {class: :info, type: :circle}
  end
end
