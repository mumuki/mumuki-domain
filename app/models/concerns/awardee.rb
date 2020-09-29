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
    current_indicators.partition(&:once_completed?)
  end

  def current_indicators
    items_with_medals.map { |i| i.progress_for(self, Organization.current) }
  end

  def items_with_medals
    Usage.where(organization: Organization.current).map(&:item).select(&:medal_id)
  end
end
