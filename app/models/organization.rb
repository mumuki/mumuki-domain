class Organization < ApplicationRecord
  include Mumuki::Domain::Syncable
  include Mumuki::Domain::Helpers::Organization

  serialize :profile, Mumukit::Platform::Organization::Profile
  serialize :settings, Mumukit::Platform::Organization::Settings
  serialize :theme, Mumukit::Platform::Organization::Theme

  markdown_on :description

  validate :ensure_consistent_public_login

  belongs_to :book
  has_many :usages

  validates_presence_of :contact_email, :locale
  validates :name, uniqueness: true,
                   presence: true,
                   format: { with: Mumuki::Domain::Helpers::Organization.anchored_valid_name_regex }
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
    central? ? '' : " - #{book.name}"
  end

  def site_name
    central? ? 'mumuki' : name
  end

  # Tells if the given user can
  # ask for help in this organization
  #
  # Warning: this method does not strictly check user's permission
  def ask_for_help_enabled?(user = nil)
    report_issue_enabled? || community_link.present? || can_create_discussions?(user)
  end

  # Tells if the given user can
  # create discussion in this organization
  #
  # This is true only when this organization has a forum and the user
  # has the discusser pseudo-permission
  def can_create_discussions?(user = nil)
    forum_enabled? && (!user || user.discusser_of?(self))
  end

  def import_from_resource_h!(resource_h)
    attrs = self.class.slice_resource_h resource_h
    attrs[:book] = Book.locate! attrs[:book]
    update! attrs
  end

  def to_resource_h
    super.merge(book: book.slug)
  end

  private

  def ensure_consistent_public_login
    errors.add(:base, :consistent_public_login) if settings.customized_login_methods? && public?
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
