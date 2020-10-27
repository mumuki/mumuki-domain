module Awardee
  def acquired_medals
    @acquired_medals ||= medals_for completed_contents_here
  end

  def unacquired_medals
    @unacquired_medals ||= medals_for uncompleted_contents_here
  end

  private

  def medals_for(content)
    content.map(&:medal)
  end

  def completed_contents_here
    awardable_contents_here.select { |c| c.once_completed_for? self, Organization.current }
  end

  def uncompleted_contents_here
    awardable_contents_here.reject { |c| c.once_completed_for? self, Organization.current }
  end

  def awardable_contents_here
    @awardable_contents_here ||= Organization.current.gamification_enabled? ? Organization.current.all_contents.select(&:medal_id) : []
  end
end
