module Gamified
  def award_experience_points!
    points = net_experience

    if points > 0
      stats = UserStats.stats_for(submitter)
      stats.add_exp!(points)
      stats.save!
    end
  end

  def net_experience
    submission_status.exp_given - top_submission_status.exp_given
  end
end
