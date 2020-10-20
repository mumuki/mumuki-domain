module Awardee
  def acquired_medals
    @acquired_medals ||= medals_for awardable_content_progress_here.select(&:once_completed?)
  end

  def unacquired_medals
    @unacquired_medals ||= medals_for awardable_content_progress_here.reject(&:once_completed?)
  end

  private

  def medals_for(progress)
    Organization.current.gamification_enabled? ? progress.map { |i| i.content.medal } : []
  end

  def awardable_content_progress_here
    @awardable_content_progress_here ||= awardable_contents_here.map { |i| i.progress_for(self, Organization.current) }
  end

  def awardable_contents_here
    Usage.where(organization: Organization.current).map(&:item).select(&:medal_id)
  end
end
