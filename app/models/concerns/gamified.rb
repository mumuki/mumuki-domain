module Gamified
  def award_experience_points!
    points = net_experience

    if points > 0
      stats = user_stats_for(submitter, organization)
      stats.add_exp!(points)
      stats.save!
    end
  end

  def net_experience
    submission_status.exp_given - top_submission_status.exp_given
  end

  def user_stats_for(user, organization)
    UserStats.find_or_initialize_by(user: user, organization: organization)
  end
end
