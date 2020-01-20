class Lesson < ApplicationRecord
  include WithNumber
  include FriendlyName

  include GuideContainer

  belongs_to :topic

  include ParentNavigation, SiblingsNavigation

  alias_method :chapter, :navigable_parent

  def used_in?(organization)
    guide.usage_in_organization(organization) == self
  end

  def structural_parent
    topic
  end
end
