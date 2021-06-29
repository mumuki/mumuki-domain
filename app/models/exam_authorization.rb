class ExamAuthorization < ApplicationRecord

  belongs_to :user
  belongs_to :exam

  def start!
    update!(started: true, started_at: Time.current) unless started?
  end

end
