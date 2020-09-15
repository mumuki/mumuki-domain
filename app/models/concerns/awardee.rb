module Awardee
  def acquired_medals
    Indicator.where(organization: Organization.current, user: self).select(&:completed?).map { |i| i.content.medal }.compact
  end

  def unacquired_medals
    Indicator.where(organization: Organization.current, user: self).select {|i| !i.completed? }.map { |i| i.content.medal }.compact
  end
end