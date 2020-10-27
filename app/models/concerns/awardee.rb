module Awardee
  def acquired_medals(organization=Organization.current)
    @acquired_medals ||= medals_for awarded_contents_in(organization)
  end

  def unacquired_medals(organization=Organization.current)
    @unacquired_medals ||= medals_for unawarded_contents_in(organization)
  end

  private

  def medals_for(content)
    content.map(&:medal)
  end

  def awarded_contents_in(organization)
    awardable_contents_in(organization).first
  end

  def unawarded_contents_in(organization)
    awardable_contents_in(organization).second
  end

  def awardable_contents_in(organization)
    @awardable_contents_in ||= organization.awardable_contents.partition { |c| c.once_completed_for? self, organization }
  end
end
