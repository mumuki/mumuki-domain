class Guide < Content
  BASIC_RESOURCE_FIELDS = %i(
    authors beta collaborators corollary
    custom_expectations expectations extra id_format
    learn_more private settings sources teacher_info type)

  include WithStats,
          WithExpectations,
          WithLanguage,
          WithAssignmentsBatch

  markdown_on :corollary, :sources, :learn_more, :teacher_info

  numbered :exercises
  has_many :exercises, -> { order(number: :asc) }, dependent: :destroy

  serialize :settings, Hash

  self.inheritance_column = nil

  enum type: [:learning, :practice]

  alias_method :structural_children, :exercises

  def clear_progress!(user, organization=Organization.current)
    transaction do
      exercises.each do |exercise|
        exercise.find_assignment_for(user, organization)&.destroy!
      end
    end
  end

  def lesson
    usage_in_organization_of_type Lesson
  end

  def chapter
    lesson.try(:chapter) #FIXME temporary
  end

  def exercises_count
    exercises.count
  end

  def next_exercise(user)
    if user.present?
      user.next_exercise_at(self)
    else
      first_exercise
    end
  end

  def pending_exercises(user)
    Exercise.with_pending_assignments_for(user, exercises)
  end

  def first_exercise
    exercises.first
  end

  def search_tags
    exercises.flat_map(&:search_tags).uniq
  end

  def done_for?(user)
    stats_for(user).done?
  end

  # Finds an exercise by bibliotheca_id within this guide
  def locate_exercise!(bibliotheca_id)
    exercises.find_by!(bibliotheca_id: bibliotheca_id)
  end

  def import_from_resource_h!(resource_h)
    dirty_progress_if_structural_children_changed! do
      self.assign_attributes whitelist_attributes(resource_h)
      self.language = Language.for_name(resource_h.dig(:language, :name))
      self.save!

      resource_h[:exercises]&.each_with_index do |e, i|
        exercise = Exercise.find_by(guide_id: self.id, bibliotheca_id: e[:id])
        exercise_type = e[:type] || 'problem'

        exercise = exercise ?
            exercise.ensure_type!(exercise_type.as_module_name) :
            exercise_type.as_module.new(guide_id: self.id, bibliotheca_id: e[:id])

        exercise.import_from_resource_h! (i+1), e
      end

      new_ids = resource_h[:exercises].map { |it| it[:id] }
      self.exercises.where.not(bibliotheca_id: new_ids).destroy_all

      reload
    end
  end

  # Keep this list up to date with
  # Mumuki::Domain::Store::Github::GuideSchema
  def to_expanded_resource_h(options={})
    as_json(only: BASIC_RESOURCE_FIELDS)
      .symbolize_keys
      .merge(super)
      .merge(exercises: exercises.map { |it| it.to_resource_h(options) })
      .merge(language: language.to_embedded_resource_h)
      .tap { |it| it.markdownified!(:corollary, :description, :teacher_info) if options[:markdownified] }
  end

  def to_markdownified_resource_h
    to_resource_h(markdownified: true)
  end

  def as_lesson_of(topic)
    topic.lessons.find_by(guide_id: id) || Lesson.new(guide: self, topic: topic)
  end

  def as_complement_of(book) #FIXME duplication
    book.complements.find_by(guide_id: id) || Complement.new(guide: self, book: book)
  end

  def resettable?
    usage_in_organization.resettable?
  end

  ## Forking

  def fork_children_into!(dup, _organization, _syncer)
    dup.exercises = exercises.map(&:dup)
  end
end
