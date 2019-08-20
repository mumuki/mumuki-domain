module Mumuki::Domain::SubmissionStatus::Pending
  extend Mumuki::Domain::SubmissionStatus::Base

  def self.pending?
    true
  end

  def self.iconize
    {class: :muted, type: :circle}
  end
end
