module Awardee
  def acquired_medals
    medals_for all_medals.first
  end

  def unacquired_medals
    medals_for all_medals.second
  end

  private

  def medals_for(indicators)
    indicators.map { |i| i.content.medal }.compact
  end

  def all_medals
    current_indicators.partition(&:completed?)
  end

  def current_indicators
    Indicator.where(organization: Organization.current, user: self)
  end
end
