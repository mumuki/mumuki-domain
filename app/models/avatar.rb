class Avatar < ApplicationRecord
  has_many :users, as: :avatar

  include WithTargetAudience

  def self.sample_for(user)
    with_current_audience_for(user).sample
  end

  def self.sample
    order('RANDOM()').first
  end
end
