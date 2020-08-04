class UserStats < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  def self.stats_for(user)
    UserStats.find_or_initialize_by(user: user, organization: Organization.current)
  end

  def self.exp_for(user)
    self.stats_for(user).exp
  end

  def add_exp!(points)
    self.exp += points
  end
end
