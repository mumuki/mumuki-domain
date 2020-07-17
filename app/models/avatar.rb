class Avatar < ApplicationRecord
  include WithTargetVisualIdentity

  def self.sample
    with_current_visual_identity.order('RANDOM()').first
  end
end
