class User < ApplicationRecord
  include Mumuki::Domain::Syncable
  include WithProfile,
          WithUserNavigation,
          WithReminders,
          WithNotifications,
          WithDiscussionCreation,
          Awardee,
          WithTermsAcceptance,
          WithPreferences,
          Onomastic,
          Mumuki::Domain::Helpers::User

  prepend WithDeletedUser

  serialize :permissions, Mumukit::Auth::Permissions
  serialize :ignored_notifications, Array

  before_destroy :clean_belongings!

  has_many :api_clients,                             dependent: :delete_all
  has_many :assignments, foreign_key: :submitter_id, dependent: :delete_all
  has_many :certificates,                            dependent: :delete_all
  has_many :exam_authorizations,                     dependent: :delete_all
  has_many :exam_authorization_requests,             dependent: :delete_all
  has_many :notifications,                           dependent: :delete_all
  has_many :indicators,                              dependent: :delete_all
  has_many :user_stats, class_name: 'UserStats',     dependent: :delete_all

  has_many :discussions, foreign_key: :initiator_id
  has_many :forum_messages, -> { where.not(discussion_id: nil)  }, class_name: 'Message', foreign_key: :sender_id
  has_many :direct_messages, -> { order(created_at: :desc) }, through: :assignments, source: :messages

  has_many :submitted_exercises, through: :assignments, class_name: 'Exercise', source: :exercise

  has_many :solved_exercises,
           -> { where('assignments.submission_status' => Mumuki::Domain::Status::Submission::Passed.to_i) },
           through: :assignments,
           class_name: 'Exercise',
           source: :exercise

  belongs_to :last_exercise, class_name: 'Exercise', optional: true
  belongs_to :last_organization, class_name: 'Organization', optional: true

  has_one :last_guide, through: :last_exercise, source: :guide

  has_many :exams, through: :exam_authorizations

  enum gender: %i(female male other unspecified)
  belongs_to :avatar, polymorphic: true, optional: true

  before_validation :set_uid!
  validates :uid, presence: true

  validates :terms_of_service, acceptance: true
  after_save :welcome_to_new_organizations!, if: :gained_access_to_new_orga?
  after_initialize :init
  PLACEHOLDER_IMAGE_URL = 'user_shape.png'.freeze

  resource_fields :uid, :social_id, :email, :permissions, :verified_first_name, :verified_last_name, *profile_fields
  with_temporary_token :delete_account_token

  organic_on :notifications, :assignments

  def last_lesson
    last_guide.try(:lesson)
  end

  def messages_in_organization(organization = Organization.current)
    direct_messages.where('assignments.organization': organization)
  end

  def passed_submissions_count_in(organization)
    assignments.where(top_submission_status: Mumuki::Domain::Status::Submission::Passed.to_i, organization: organization).count
  end

  def submissions_count
    assignments.pluck(:submissions_count).sum
  end

  def passed_submissions_count
    passed_assignments.count
  end

  def submitted_exercises_count
    submitted_exercises.count
  end

  def solved_exercises_count
    solved_exercises.count
  end

  def passed_assignments
    assignments.where(status: Mumuki::Domain::Status::Submission::Passed.to_i)
  end

  def visit!(organization)
    update!(last_organization: organization) if organization != last_organization
  end

  def to_s
    "#{id}:#{name}:#{uid}"
  end

  def never_submitted?
    last_submission_date.nil?
  end

  def clear_progress!
    transaction do
      update! last_submission_date: nil, last_exercise: nil
      assignments.destroy_all
    end
  end

  def restore_organization_progress!(organization)
    assignments_in_organization(organization).each do |assignment|
      assignment.tap(&:parent).save!
    end
  end

  def has_assignments_in_organization?(organization)
    assignments_in_organization(organization).exists?
  end

  def accept_invitation!(invitation)
    make_student_of! invitation.course_slug
  end

  def transfer_progress_to!(another)
    transaction do
      assignments.update_all(submitter_id: another.id)
      if another.never_submitted? || last_submission_date.try { |it| it > another.last_submission_date }
        another.update! last_submission_date: last_submission_date,
                        last_exercise: last_exercise,
                        last_organization: last_organization
      end
    end
    reload
  end

  def import_from_resource_h!(json)
    update! self.class.slice_resource_h json
  end

  def to_resource_h
    super.merge(image_url: profile_picture)
  end

  def verify_name!(force: false)
    if force
      self.verified_first_name = first_name
      self.verified_last_name = last_name
    else
      self.verified_first_name ||= first_name
      self.verified_last_name ||= last_name
    end
    save!
  end

  def unsubscribe_from_reminders!
    update! accepts_reminders: false
  end

  def attach!(role, course)
    add_permission! role, course.slug
    save_and_notify!
  end

  def detach!(role, course, deep: false)
    make_ex_student_of! course.slug if !deep && student_of?(course.slug) && solved_any_exercises?(course.organization)
    remove_permission! role, course.slug
    save_and_notify!
  end

  def interpolations
    {
        'user_email' => email,
        'user_first_name' => first_name,
        'user_last_name' => last_name
    }
  end

  def currently_in_exam?
    exams.any? { |e| e.in_progress_for? self }
  end

  def custom_profile_picture
    avatar&.image_url || image_url
  end

  def profile_picture
    custom_profile_picture || placeholder_image_url
  end

  def bury!
    # TODO change avatar
    update! self.class.buried_profile.merge(accepts_reminders: false, gender: nil, birthdate: nil)
  end

  # Takes a didactic - ordered - sequence of content containers
  # and returns those that have been completed
  def completed_containers(sequence, organization)
    sequence.take_while { |it| it.content.completed_for?(self, organization) }
  end

  # Like `completed_containers`, returns a slice of the completed containers
  # in the sequence, but adding a configurable number of trailing, non-completed contaienrs
  def completed_containers_with_lookahead(sequence, organization, lookahead: 1)
    raise 'invalid lookahead' if lookahead < 1

    count = completed_containers(sequence, organization).size
    sequence[0..count + lookahead - 1]
  end

  def can_discuss_in?(organization)
    organization.access_mode(self).discuss_here?
  end

  def trusted_as_discusser_in?(organization)
    trusted_for_forum? || !organization.forum_only_for_trusted?
  end

  def can_discuss_here?
    can_discuss_in? Organization.current
  end

  def can_access_teacher_info_in?(organization)
    teacher_of?(organization) || organization.teacher_training?
  end

  def name_initials
    name.split.map(&:first).map(&:capitalize).join(' ')
  end

  def abbreviated_name
    "#{first_name} #{last_name.first.capitalize + '.' if last_name.present?}".strip
  end

  def progress_at(content, organization)
    Indicator.find_or_initialize_by(user: self, organization: organization, content: content)
  end

  def build_assignment(exercise, organization)
    Assignment.build_for(self, exercise, organization)
  end

  def pending_siblings_at(content)
    content.pending_siblings_for(self)
  end

  def next_exercise_at(guide)
    guide.pending_exercises(self).order('exercises.number asc').first
  end

  def run_submission!(submission, assignment, evaluation)
    submission.run! assignment, evaluation
  end

  def incognito?
    false
  end

  def current_audience
    current_organic_context&.target_audience
  end

  def placeholder_image_url
    PLACEHOLDER_IMAGE_URL
  end

  def age
    if birthdate.present?
      @age ||= Time.current.round_years_since(birthdate.in_time_zone)
    end
  end

  def current_organic_context
    Organization.current? ?  Organization.current : main_organization
  end

  def current_immersive_context_at(path_item)
    if Organization.current?
      immersive_organization_at(path_item) || Organization.current
    else
      main_organization
    end
  end

  def notify_permissions_changed!
    return if permissions_before_last_save == permissions
    Mumukit::Nuntius.notify! 'user-permissions-changed', user: {
      uid: uid,
      old_permissions: permissions_before_last_save.as_json,
      new_permissions: permissions.as_json
    }
  end

  def solved_any_exercises?(organization = Organization.current)
    Assignment.exists?(organization: organization, submitter: self)
  end

  def save_and_notify!
    save!
    notify_permissions_changed!
    self
  end

  def current_immersive_context_and_content_at(path_item)
    immersive_organization_with_content_at(path_item).tap do |orga, _|
      return [Organization.current, path_item] unless orga.present?
    end
  end

  def certificates_in_organization(organization = Organization.current)
    certificates.where certificate_program: CertificateProgram.where(organization: organization)
  end

  def certificated_in?(certificate_program)
    certificates.where(certificate_program: certificate_program).exists?
  end

  def certificate_in(certificate_program, certificate_h)
    return if certificated_in?(certificate_program)
    certificate = certificates.create certificate_h.merge(certificate_program: certificate_program)
    UserMailer.certificate(certificate).post!
  end

  def clear_progress_for!(organization)
    location = { organization: organization }.compact

    target_assignments = assignments.where(location)

    direct_messages.where(assignment: target_assignments).delete_all

    target_assignments.delete_all
    indicators.where(location).delete_all
    user_stats.where(location).delete_all
  end

  def notify_via_email!(notification)
    UserMailer.notification(notification).post! unless ignores_notification? notification
  end

  def ignores_notification?(notification)
    ignored_notifications.include? notification.subject
  end

  def clean_belongings!
    discussions.update_all initiator_id: User.deleted_user.id
    forum_messages.update_all sender_id: User.deleted_user.id
    direct_messages.where(sender: self).delete_all
  end

  private

  def welcome_to_new_organizations!
    new_accessible_organizations.each do |organization|
      UserMailer.welcome_email(self, organization).post! rescue nil if organization.greet_new_users?
    end
  end

  def gained_access_to_new_orga?
    new_accessible_organizations.present?
  end

  def new_accessible_organizations
    return [] unless saved_change_to_permissions?

    old, new = saved_change_to_permissions
    new_organizations = (new.any_granted_organizations - old.any_granted_organizations).to_a
    Organization.where(name: new_organizations)
  end

  def set_uid!
    self.uid ||= email
  end

  def init
    if custom_profile_picture.blank?
      self.avatar = Avatar.sample_for(self)
      save if persisted?
    end
  end

  def self.sync_key_id_field
    :uid
  end

  def self.create_if_necessary(user)
    user[:uid] ||= user[:email]
    where(uid: user[:uid]).first_or_create(user)
  end

  # Call this method once as part of application initialization
  # in order to enable user profile override as part of disabling process
  def self.configure_buried_profile!(profile)
    @buried_profile = profile
  end

  def self.buried_profile
    (@buried_profile || {}).slice(:first_name, :last_name, :email)
  end
end
