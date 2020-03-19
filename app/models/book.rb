class Book < Content
  numbered :chapters
  aggregate_of :chapters
  aggregate_of :complements

  has_many :chapters, -> { order(number: :asc) }, dependent: :destroy
  has_many :topics, through: :chapters
  has_many :complements, dependent: :destroy

  has_many :exercises, through: :chapters
  has_many :discussions, through: :exercises
  organic_on :discussions

  delegate :first_lesson, to: :first_chapter

  alias_method :structural_children, :chapters

  def to_s
    slug
  end

  def first_chapter
    chapters.first
  end

  def next_lesson_for(user)
    user.try(:last_lesson) || first_lesson
  end

  def import_from_resource_h!(resource_h)
    dirty_progress_if_structural_children_changed! do
      self.assign_attributes resource_h.except(:chapters, :complements, :id, :description)
      self.description = resource_h[:description]&.squeeze(' ')

      rebuild_chapters! resource_h[:chapters].map { |it| Topic.find_by!(slug: it).as_chapter_of(self) }
      rebuild_complements! resource_h[:complements].to_a.map { |it| Guide.find_by(slug: it)&.as_complement_of(self) }.compact
    end
  end

  def to_expanded_resource_h
    super.merge(
      chapters: chapters.map(&:slug),
      complements: complements.map(&:slug))
  end

  def index_usage!(organization)
    organization.index_usage_of! self, self
    [chapters, complements].flatten.each { |item| item.index_usage! organization }
  end

  def reindex_usages!
    Organization.where(book: self).each &:reindex_usages!
  end

  ## Forking

  def fork_children_into!(dup, organization, syncer)
    dup.chapters = chapters.map { |chapter| chapter.topic.fork_to!(organization, syncer, quiet: true).as_chapter_of(dup) }
    dup.complements = complements.map { |complement| complement.guide.fork_to!(organization, syncer, quiet: true).as_complement_of(dup) }
  end

  def structural_parent
    nil
  end

  ## workspace

  ## Answers the chapters that are members
  ## of the given workspace
  def chapter_access_levels_in(workspace)
    workspace.access_levels_for(chapters)
  end

  def enabled_chapters_of(workspace)
    chapter_access_levels_in(workspace).select { |_, access_level| access_level.like? :enabled }.keys
  end
end
