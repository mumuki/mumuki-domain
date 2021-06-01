module WithResponsibleModerator
  extend ActiveSupport::Concern

  MODERATOR_MAX_RESPONSIBLE_TIME = 45.minutes

  def toggle_responsible!(moderator)
    if responsible?(moderator)
      no_responsible!
    elsif no_current_responsible?
      responsible! moderator
    end
  end

  def any_responsible?
    responsible_moderator_at.present? && (responsible_moderator_at + MODERATOR_MAX_RESPONSIBLE_TIME).future?
  end

  def no_current_responsible?
    !any_responsible?
  end

  def responsible?(moderator)
    any_responsible? && responsible_moderator_by == moderator
  end

  def current_responsible_visible_for?(user)
    user&.moderator_here? && any_responsible?
  end

  private

  def responsible!(moderator)
    update! responsible_moderator_at: Time.now, responsible_moderator_by: moderator
  end

  def no_responsible!
    update! responsible_moderator_at: nil, responsible_moderator_by: nil
  end
end
