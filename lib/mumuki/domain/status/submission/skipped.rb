module Mumuki::Domain::Status::Submission::Skipped
  extend Mumuki::Domain::Status::Submission

  def self.skipped?
    true
  end

  def self.iconize
    {class: :success, type: 'check-circle'}
  end
end
