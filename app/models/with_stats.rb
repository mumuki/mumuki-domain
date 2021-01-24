module WithStats
  def stats_for(user)
    return unless user.present?
    Stats.from_statuses statuses_for(user)
  end

  def started?(user)
    stats_for(user).started?
  end
end
