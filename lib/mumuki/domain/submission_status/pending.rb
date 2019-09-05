module Mumuki::Domain::SubmissionStatus::Pending
  def self.pending?
    true
  end

  def self.iconize
    {class: :muted, type: :circle}
  end
end
