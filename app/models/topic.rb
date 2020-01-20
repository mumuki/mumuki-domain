class Topic < Content
  numbered :lessons
  aggregate_of :lessons

  has_many :lessons, -> { order(number: :asc) }, dependent: :delete_all

  has_many :guides, -> { order('lessons.number') }, through: :lessons
  has_many :exercises, -> { order('exercises.number') }, through: :guides

  markdown_on :appendix

  alias_method :children, :guides

  def first_lesson
    lessons.first
  end

  def import_from_resource_h!(resource_h)
    dirty_progress_if_children_changed! do
      self.assign_attributes resource_h.except(:lessons, :description)
      self.description = resource_h[:description].squeeze(' ')
      rebuild_lessons! resource_h[:lessons].to_a.map { |it| lesson_for(it) }
    end
  end

  def to_expanded_resource_h
    super.merge(appendix: appendix, lessons: lessons.map(&:slug))
  end

  def as_chapter_of(book)
    book.chapters.find_by(topic_id: id) || Chapter.new(topic: self, book: book)
  end

  def reindex_usages!
    Chapter.where(topic: self).map(&:book).each(&:reindex_usages!)
  end

  ## Forking

  def fork_children_into!(dup, organization, syncer)
    dup.lessons = lessons.map { |lesson| lesson.guide.fork_to!(organization, syncer, quiet: true).as_lesson_of(dup) }
  end

  private

  def lesson_for(slug)
    Guide.find_by!(slug: slug).as_lesson_of(self)
  rescue ActiveRecord::RecordNotFound
    raise "Guide for slug #{slug} could not be found"
  end
end
