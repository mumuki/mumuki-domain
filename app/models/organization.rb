class Organization < ApplicationRecord
  include Mumuki::Domain::Syncable
  include Mumuki::Domain::Helpers::Organization
  include Mumuki::Domain::Area

  include Mumukit::Login::OrganizationHelpers

  include WithTargetAudience

  serialize :profile, Mumuki::Domain::Organization::Profile
  serialize :settings, Mumuki::Domain::Organization::Settings
  serialize :theme, Mumuki::Domain::Organization::Theme

  markdown_on :description, :display_description, :page_description
  teaser_on :display_description

  validate :ensure_consistent_public_login
  validate :ensure_valid_activity_range

  belongs_to :book
  has_many :usages

  validates_presence_of :contact_email, :locale
  validates_presence_of :welcome_email_template, if: :greet_new_users?
  validates :name, uniqueness: true,
                   presence: true,
                   format: { with: Mumukit::Platform::Organization.anchored_valid_name_regex }
  validates :locale, inclusion: { in: Mumukit::Platform::Locale.supported }

  after_create :reindex_usages!
  after_update :reindex_usages!, if: lambda { |user| user.saved_change_to_book_id? }

  has_many :guides, through: 'usages', source: 'item', source_type: 'Guide'
  has_many :exercises, through: :guides
  has_many :assignments, through: :exercises
  has_many :exams
  has_many :courses

  resource_fields :name, :book, :profile, :settings, :theme

  defaults do
    self.class.base.try do |base|
      self.theme         = base.theme    if theme.empty?
      self.settings      = base.settings if settings.empty?
      self.contact_email ||= base.contact_email
      self.book          ||= base.book
      self.locale        ||= base.locale
    end
  end

  def in_path?(item)
    usages.exists?(item: item) || usages.exists?(parent_item: item)
  end

  def notify_recent_assignments!(date)
    notify_assignments! assignments.where('assignments.updated_at > ?', date)
  end

  def notify_assignments_by!(submitter)
    notify_assignments! assignments.where(submitter_id: submitter.id)
  end

  def silent?
    test?
  end

  def reindex_usages!
    transaction do
      drop_usage_indices!
      book.index_usage! self
      exams.each { |exam| exam.index_usage! self }
    end
    reload
  end

  def drop_usage_indices!
    usages.destroy_all
  end

  def index_usage_of!(item, parent)
    Usage.create! organization: self, item: item, parent_item: parent
  end

  def accessible_exams_for(user)
    exams.select { |exam| exam.accessible_for?(user) }
  end

  def has_login_method?(login_method)
    self.login_methods.include? login_method.to_s
  end

  def explain_error(code, advice)
    errors_explanations.try { |it| it[code.to_s] } || I18n.t(advice)
  end

  def self.accessible_as(user, role)
    all.select { |it| it.public? || user.has_permission?(role, it.slug) }
  end

  def title_suffix
    warn "Don't use title_suffix. Use page_name instead"
    " - #{page_name}"
  end

  def site_name
    warn "Don't use site_name. Use display_name instead"
    name
  end

  # Tells if the given user can
  # ask for help in this organization
  #
  # Warning: this method does not strictly check user's permission
  def ask_for_help_enabled?(user)
    report_issue_enabled? || community_link.present? || user.can_discuss_in?(self)
  end

  def import_from_resource_h!(resource_h)
    attrs = self.class.slice_resource_h resource_h
    attrs[:book] = Book.locate! attrs[:book]
    update! attrs
  end

  def to_resource_h
    super.merge(book: book.slug)
  end

  def to_organization
    self
  end

  def enable_progressive_display!(lookahead: 1)
    update! progressive_display_lookahead: lookahead
  end

  def progressive_display_lookahead=(lookahead)
    self[:progressive_display_lookahead] = lookahead&.positive? ? lookahead : nil
  end

  # ==============
  # Display fields
  # ==============

  def display_name
    self[:display_name].presence || name.try { |it| it.gsub(/\W/, ' ').titleize }
  end

  def display_description
    self[:display_description].presence || I18n.t('defaults.organization.display_description', name: name)
  end

  # ===========
  # Page fields
  # ===========

  # Since an organization has a single book, both concepts may be merged
  # when describing a site. In such contexts, wins_page?
  # control whether the book or the organization header fields are
  # more important

  def page_name
    wins_page? ? display_name : book.name
  end

  def page_description
    wins_page? ? display_description : book.description
  end

  private

  def ensure_consistent_public_login
    errors.add(:base, :consistent_public_login) if settings.customized_login_methods? && public?
  end

  def ensure_valid_activity_range
    if in_preparation_until.present? && disabled_from.present?
      errors.add(:base, :invalid_activity_range) if in_preparation_until.to_datetime >= disabled_from.to_datetime
    end
  end

  def notify_assignments!(assignments)
    assignments.each { |assignment| assignment.notify! }
  end

  class << self
    def central
      find_by name: 'central'
    end

    def base
      find_by name: 'base'
    end

    def silenced?
      !Mumukit::Platform::Organization.current? || current.silent?
    end

    def sync_key_id_field
      :name
    end

    # Answers organizations that have the given item
    # in their paths.
    #
    # Warning: unlike `in_path?`, this method does only work with
    # content - child - items instead of both kind of items - content and content containers.
    #
    # See `Organization#in_path?`
    def in_path(content)
      joins(:usages).where('usages.item': content).distinct
    end
  end
end
