module Gamified
  def award_experience_points!
    stats = user_stats_for(submitter, organization)
    stats.exp += submission_status.exp_given
    stats.save!
  end

  def user_stats_for(user, organization)
    UserStats.find_or_initialize_by(user: user, organization: organization)
  end
end
