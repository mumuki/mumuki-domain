module Awardee
  def medals
    Indicator.where(organization: Organization.current, user: self).select(&:completed?).map { |i| i.content.medal }.compact
  end
end