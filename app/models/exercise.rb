class Exercise < ApplicationRecord
  RANDOMIZED_FIELDS = [:default_content, :description, :extra, :hint, :test]
  BASIC_RESOURCE_FIELDS = %i(
    name layout editor corollary teacher_info manual_evaluation locale
    choices assistance_rules randomizations tag_list extra_visible goal
    free_form_editor_source initial_state final_state)

  include WithDescription
  include WithLocale
  include WithNumber,
          WithName,
          WithAssignments,
          FriendlyName,
          WithLanguage,
          Assistable,
          WithRandomizations,
          WithDiscussions

  include Submittable,
          Questionable

  include SiblingsNavigation,
          ParentNavigation

  belongs_to :guide

  markdown_on :teacher_info

  defaults { self.submissions_count = 0 }

  serialize :choices, Array
  serialize :settings, Hash

  validates_presence_of :submissions_count,
                        :guide, :bibliotheca_id

  randomize(*RANDOMIZED_FIELDS)
  delegate :timed?, to: :navigable_parent

  def console?
    queriable?
  end

  def used_in?(organization=Organization.current)
    guide.usage_in_organization(organization).present?
  end

  def pending_siblings_for(user)
    guide.pending_exercises(user)
  end

  def structural_parent
    guide
  end

  def guide_done_for?(user)
    guide.done_for?(user)
  end

  def previous
    sibling_at number.pred
  end

  def sibling_at(index)
    index = number + index unless index.positive?
    guide.exercises.find_by(number: index)
  end

  def search_tags
    [language&.name, *tag_list].compact
  end

  def transparent_id
    "#{guide.transparent_id}/#{bibliotheca_id}"
  end

  def transparent_params
    guide.transparent_params.merge(bibliotheca_id: bibliotheca_id)
  end

  def friendly
    defaulting_name { "#{navigable_parent.friendly} - #{name}" }
  end

  def submission_for(user)
    assignment_for(user).submission
  end

  def new_solution
    Mumuki::Domain::Submission::Solution.new(content: default_content)
  end

  def import_from_resource_h!(number, resource_h)
    self.language = Language.for_name(resource_h.dig(:language, :name)) || guide.language
    self.locale = guide.locale

    reset!

    attrs = whitelist_attributes(resource_h, except: [:type, :id])
    attrs[:choices] = resource_h[:choices].to_a
    attrs[:bibliotheca_id] = resource_h[:id]
    attrs[:number] = number
    attrs[:manual_evaluation] ||= false
    attrs = attrs.except(:expectations, :custom_expectations) if type != 'Problem'

    assign_attributes(attrs)
    save!
  end

  def choice_values
    choices.map { |it| it.indifferent_get(:value) }
  end

  def choice_index_for(value)
    choice_values.index(value)
  end

  def to_resource_h(*args)
    to_expanded_resource_h(*args).compact
  end

  # Keep this list up to date with
  # Mumuki::Domain::Store::Github::ExerciseSchema
  def to_expanded_resource_h(options={})
    language_resource_h = language.to_embedded_resource_h if language != guide.language
    as_json(only: BASIC_RESOURCE_FIELDS)
      .merge(id: bibliotheca_id, language: language_resource_h, type: type.underscore)
      .merge(expectations: self[:expectations])
      .merge(custom_expectations: self[:custom_expectations])
      .merge(settings: self[:settings])
      .merge(RANDOMIZED_FIELDS.map { |it| [it, self[it]] }.to_h)
      .symbolize_keys
      .tap { |it| it.markdownify!(:hint, :corollary, :description, :teacher_info) if options[:markdownified] }
  end

  def reset!
    self.name = nil
    self.description = nil
    self.corollary = nil
    self.hint = nil
    self.extra = nil
    self.tag_list = []
  end

  def ensure_type!(type)
    if self.type != type
      reclassify! type
    else
      self
    end
  end

  def reclassify!(type)
    update!(type: type)
    Exercise.find(id)
  end

  def messages_path_for(user)
    "api/guides/#{guide.slug}/#{bibliotheca_id}/student/#{URI.escape user.uid}/messages?language=#{language}"
  end

  def messages_url_for(user)
    Mumukit::Platform.classroom_api.organic_url_for(Organization.current, messages_path_for(user))
  end

  def description_context
    Mumukit::ContentType::Markdown.to_html splitted_description.first
  end

  def splitted_description
    description.split('> ')
  end

  def description_task
    Mumukit::ContentType::Markdown.to_html splitted_description.drop(1).join("\n")
  end

  def custom?
    false
  end

  def inspection_keywords
    {}
  end

  # Submits the user solution
  # only if the corresponding assignment has attemps left
  def try_submit_solution!(user, solution={})
    assignment = assignment_for(user)
    if assignment.attempts_left?
      submit_solution!(user, solution)
    else
      assignment
    end
  end

  def limited?
    navigable_parent.limited_for?(self)
  end

  def files_for(current_content)
    language
      .directives_sections
      .split_sections(current_content)
      .map { |name, content| Mumuki::Domain::File.new name, content }
  end

  def self.find_transparently!(params)
    Guide.find_transparently!(params).locate_exercise! params[:bibliotheca_id]
  end

  def self.locate!(slug_and_bibliotheca_id)
    slug, bibliotheca_id = slug_and_bibliotheca_id
    Guide.locate!(slug).locate_exercise! bibliotheca_id
  end

  def settings
    guide.settings.deep_merge super
  end

  private

  def evaluation_class
    if manual_evaluation?
      manual_evaluation_class
    else
      automated_evaluation_class
    end
  end

  def manual_evaluation_class
    Mumuki::Domain::Evaluation::Manual
  end

  def automated_evaluation_class
    Mumuki::Domain::Evaluation::Automated
  end

  def self.default_layout
    layouts.keys[0]
  end
end
