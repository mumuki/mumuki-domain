class UserStats < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  def self.stats_for(user)
    UserStats.find_or_initialize_by(user: user, organization: Organization.current)
  end

  def self.exp_for(user)
    self.stats_for(user).exp
  end

  def self.game_mode_enabled_for?(user)
    self.stats_for(user).game_mode_enabled?
  end

  def add_exp!(points)
    self.exp += points
  end
end
