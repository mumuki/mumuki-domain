module WithResponsibleModerator
  extend ActiveSupport::Concern

  def toggle_responsible!(moderator)
    if any_responsible?
      no_responsible!
    else
      responsible! moderator
    end
  end

  def any_responsible?
    responsible_moderator_at.present?
  end

  private

  def responsible!(moderator)
    update! responsible_moderator_at: Time.now, responsible_moderator_by: moderator
  end

  def no_responsible!
    update! responsible_moderator_at: nil, responsible_moderator_by: nil
  end
end
