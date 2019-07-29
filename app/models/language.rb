class Language < ApplicationRecord
  include WithCaseInsensitiveSearch
  include Mumuki::Domain::Syncable

  enum output_content_type: [:plain, :html, :markdown]

  validates_presence_of :runner_url, :output_content_type

  validates :name, presence: true, uniqueness: {case_sensitive: false}

  # This list must kept up to date with
  # Mumukit::Sync::Store::Thesaurus::InfoConverter
  resource_fields :comment_type,
                  :devicon,
                  :editor_css_urls,
                  :editor_html_urls,
                  :editor_js_urls,
                  :editor_shows_loading_content,
                  :extension,
                  :feedback,
                  :highlight_mode,
                  :layout_css_urls,
                  :layout_html_urls,
                  :layout_js_urls,
                  :layout_shows_loading_content,
                  :multifile,
                  :settings,
                  :name,
                  :output_content_type,
                  :prompt,
                  :queriable,
                  :runner_url,
                  :stateful_console,
                  :test_extension,
                  :test_template,
                  :triable,
                  :visible_success_output

  markdown_on :description

  delegate :run_tests!, :run_query!, :run_try!, to: :bridge

  def bridge
    Mumukit::Bridge::Runner.new(runner_url)
  end

  def highlight_mode
    self[:highlight_mode] || name
  end

  def output_content_type
    Mumukit::ContentType.for(self[:output_content_type])
  end

  def to_s
    name
  end

  def self.for_name(name)
    find_by_ignore_case!(:name, name) if name
  end

  def devicon
    self[:devicon] || name.downcase
  end

  def sync_key
    Mumukit::Sync.key :language, runner_url
  end

  def import_from_resource_h!(resource_h)
    assign_attributes resource_h.except(:runner_url)
    save!
  end

  def directives_sections
    new_directive Mumukit::Directives::Sections
  end


  def assets_urls_for(kind, content_type)
    send "#{kind}_#{content_type}_urls"
  end

  # TODO this should be a Mumukit::Directives::Directive
  # and be part of a pipeline
  def interpolate_references_for(assignment, field)
    interpolate(field, assignment.submitter.interpolations, lambda { |content| replace_content_reference(assignment, content) })
  end

  def to_embedded_resource_h
    as_json(only: [:name, :extension, :test_extension]).symbolize_keys
  end

  private

  # TODO we should use Mumukit::Directives::Pipeline
  def interpolate(interpolee, *interpolations)
    interpolee = interpolee || ''
    interpolations.inject(interpolee) { |content, interpolation| directives_interpolations.interpolate(content, interpolation).first }
  end

  def directives_interpolations
    new_directive Mumukit::Directives::Interpolations
  end

  def replace_content_reference(assignment, interpolee)
    case interpolee
    when /previousContent|previousSolution/
      assignment.current_content_at(-1)
    when /(solution|content)\[(-?\d*)\]/
      assignment.current_content_at($2.to_i)
    end
  end

  def new_directive(directive_type)
    directive_type.new.tap { |it| it.comment_type = directives_comment_type }
  end

  def directives_comment_type
    Mumukit::Directives::CommentType.parse comment_type
  end

  def self.sync_key_id_field
    :runner_url
  end
end
