class Avatar < ApplicationRecord
  def self.sample
    Avatar.order('RANDOM()').first
  end
end
