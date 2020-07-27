class Avatar < ApplicationRecord
  include WithTargetVisualIdentity

  def self.sample_for(user)
    with_current_audience_for(user).sample
  end

  def self.sample
    order('RANDOM()').first
  end
end
