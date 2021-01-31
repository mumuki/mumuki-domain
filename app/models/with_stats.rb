module WithStats
  def stats_for(user)
    Stats.from_statuses statuses_for(user) if user
  end

  def assignments_and_stats_for(user)
    return unless user

    assignments = assignments_for(user)
    [ assignments, Stats.from_statuses(assignments.map(&:status)) ]
  end

  def started?(user)
    stats_for(user).started?
  end
end
