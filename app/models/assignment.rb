class Assignment < Progress
  include Contextualization
  include WithMessages
  include Gamified

  markdown_on :extra_preview

  belongs_to :exercise
  has_one :guide, through: :exercise
  has_many :messages, -> { order(date: :desc) }, dependent: :destroy

  belongs_to :organization
  belongs_to :submitter, class_name: 'User'

  validates_presence_of :exercise, :submitter

  delegate :language, :name, :navigable_parent, :settings,
           :limited?, :input_kids?, :choice?, :results_hidden?, to: :exercise

  delegate :completed?, :solved?, to: :submission_status

  delegate :content_available_in?, to: :parent

  alias_attribute :status, :submission_status
  alias_attribute :attempts_count, :attemps_count

  scope :by_exercise_ids, -> (exercise_ids) do
    where(exercise_id: exercise_ids) if exercise_ids
  end

  scope :by_usernames, -> (usernames) do
    joins(:submitter).where('users.name' => usernames) if usernames
  end

  defaults do
    self.query_results = []
    self.expectation_results = []
  end

  alias_method :parent_content, :guide
  alias_method :user, :submitter

  after_initialize :set_default_top_submission_status
  before_save :award_experience_points!, :update_top_submission!, if: :submission_status_changed?
  after_save :dirty_parent_by_submission!, if: :completion_changed?

  def set_default_top_submission_status
    self.top_submission_status ||= 0
  end

  def completion_changed?
    completed_before_last_save? != completed?
  end

  def completed_before_last_save?
    status_before_last_save.completed?
  end

  def evaluate_manually!(teacher_evaluation)
    update! status: teacher_evaluation[:status], manual_evaluation_comment: teacher_evaluation[:manual_evaluation]
  end

  def visible_status
    if results_hidden? && !pending?
      :manual_evaluation_pending.to_submission_status
    else
      super
    end
  end

  def randomized_values
    exercise.randomizer.randomized_values(submitter.id)
  end

  def save_submission!(submission)
    transaction do
      update! submission_id: submission.id
      update! submitted_at: Time.current
      update_submissions_count!
      update_last_submission!
    end
  end

  def extension
    exercise.language.extension
  end

  def notify!
    unless Organization.silenced?
      update_misplaced!(current_notification_contexts.size > 1)
      Mumukit::Nuntius.notify! 'submissions', to_resource_h
    end
  end

  def current_notification_contexts
    [Organization.current, submitter.current_immersive_context_at(exercise)].uniq
  end

  def notify_to_accessible_organizations!
    warn "Don't use notify_to_accessible_organizations!. Use notify_to_student_granted_organizations! instead"
    notify_to_student_granted_organizations!
  end

  def notify_to_student_granted_organizations!
    submitter.student_granted_organizations.each do |organization|
      organization.switch!
      notify!
    end
  end

  def self.evaluate_manually!(teacher_evaluation)
    Assignment.find_by(submission_id: teacher_evaluation[:submission_id])&.evaluate_manually! teacher_evaluation
  end

  def content=(content)
    if exercise.solvable?
      self.solution = exercise.single_choice? ? exercise.choice_index_for(content) : content
    end
  end

  def test
    exercise.test && language.interpolate_references_for(self, exercise.test)
  end

  def extra
    exercise.extra && language.interpolate_references_for(self, exercise.extra)
  end

  def extra_preview
    Mumukit::ContentType::Markdown.highlighted_code(language.name, extra)
  end

  def run_update!
    running!
    begin
      update! yield
    rescue => e
      errored! e.message
      raise e
    end
  end

  def manual_evaluation_pending!
    update! submission_status: :manual_evaluation_pending
  end

  def passed!
    update! submission_status: :passed
  end

  def skipped!
    update! submission_status: :skipped
  end

  def running!
    update! submission_status: :running,
            result: nil,
            test_results: nil,
            expectation_results: [],
            manual_evaluation_comment: nil
  end

  def errored!(message)
    update! result: message, submission_status: :errored
  end

  %w(query try).each do |key|
    name = "run_#{key}!"
    define_method(name) { |params| exercise.send name, params.merge(extra: extra, settings: settings) }
  end

  def run_tests!(params)
    exercise.run_tests! params.merge(extra: extra, test: test, settings: settings)
  end

  def to_resource_h
    excluded_fields = %i(created_at exercise_id id organization_id parent_id solution submission_id
                         submission_status submitted_at submitter_id top_submission_status updated_at misplaced)

    as_json(except: excluded_fields,
              include: {
                guide: {
                  only: [:slug, :name],
                  include: {
                    lesson: {only: [:number]},
                    language: {only: [:name]}},
                },
                exercise: {only: [:name, :number]},
                submitter: {only: [:email, :social_id, :uid], methods: [:name, :profile_picture]}})
      .deep_merge(
        'organization' => Organization.current.name,
        'sid' => submission_id,
        'created_at' => submitted_at || updated_at,
        'content' => solution,
        'status' => submission_status,
        'exercise' => {
          'eid' => exercise.bibliotheca_id
        },
        'guide' => {'parent' => {
          'type' => navigable_parent.class.to_s,
          'name' => navigable_parent.name,
          'position' => navigable_parent.try(:number),
          'chapter' => guide.chapter.as_json(only: [:id], methods: [:name])
        }})
      .merge({'randomized_values' => randomized_values.presence}.compact)
  end

  def tips
    @tips ||= exercise.assist_with(self)
  end

  def increment_attempts!
    self.attempts_count += 1 if should_retry?
  end

  def attempts_left
    navigable_parent.attempts_left_for(self)
  end

  # Tells whether the submitter of this
  # assignment can keep on sending submissions
  # which is true for non limited or for assignments
  # that have not reached their submissions limit
  def attempts_left?
    !limited? || attempts_left > 0
  end

  def current_content
    solution || default_content
  end

  def current_content_at(index)
    exercise.sibling_at(index).assignment_for(submitter).current_content
  end

  def default_content
    @default_content ||= language.interpolate_references_for(self, exercise.default_content)
  end

  def files
    exercise.files_for(current_content)
  end

  def update_top_submission!
    self.top_submission_status = submission_status unless submission_status.improved_by?(top_submission_status)
  end

  def update_misplaced!(value)
    update! misplaced: value if value != misplaced?
  end

  def self.build_for(user, exercise, organization)
    Assignment.new submitter: user, exercise: exercise, organization: organization
  end

  private

  def duplicates_key
    { exercise: exercise, submitter: submitter }
  end

  def update_submissions_count!
    self.class.connection.execute(
      "update exercises
         set submissions_count = submissions_count + 1
        where id = #{exercise.id}")
    self.class.connection.execute(
      "update assignments
         set submissions_count = submissions_count + 1
        where id = #{id}")
    exercise.reload
  end

  def update_last_submission!
    submitter.update!(last_submission_date: Time.current, last_exercise: exercise)
  end
end
