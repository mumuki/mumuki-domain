class ExamAuthorization < ApplicationRecord

  belongs_to :user
  belongs_to :exam

  def start!(new_session_id)
    if started?
      raise Mumuki::Domain::ForbiddenError if session_id.present? && session_id != new_session_id
    else
      update!(started: true, session_id: new_session_id, started_at: Time.now)
    end
  end

end
