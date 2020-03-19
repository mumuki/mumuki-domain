class Lesson < ApplicationRecord
  include WithNumber
  include FriendlyName

  include ParentNavigation, SiblingsNavigation

  include GuideContainer

  belongs_to :topic

  alias_method :chapter, :navigable_parent

  def used_in?(organization)
    guide.usage_in_organization(organization) == self
  end

  def structural_parent
    topic
  end

  def pending_siblings_for(user)
    topic.pending_lessons(user)
  end
end
