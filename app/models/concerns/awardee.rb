module Awardee
  def acquired_medals
    medals_for current_indicators.select(&:once_completed?)
  end

  def unacquired_medals
    medals_for current_indicators.reject(&:once_completed?)
  end

  private

  def medals_for(indicators)
    indicators.map { |i| i.content.medal }.compact
  end

  def current_indicators
    items_with_medals.map { |i| i.progress_for(self, Organization.current) }
  end

  def items_with_medals
    Usage.where(organization: Organization.current).map(&:item).select(&:medal_id)
  end
end
