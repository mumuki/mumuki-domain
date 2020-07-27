class User < ApplicationRecord
  include Mumuki::Domain::Syncable
  include WithProfile,
          WithUserNavigation,
          WithReminders,
          WithDiscussionCreation,
          Disabling,
          Mumuki::Domain::Helpers::User

  serialize :permissions, Mumukit::Auth::Permissions

  has_many :assignments, foreign_key: :submitter_id

  has_many :messages, -> { order(created_at: :desc) }, through: :assignments

  has_many :submitted_exercises, through: :assignments, class_name: 'Exercise', source: :exercise

  has_many :solved_exercises,
           -> { where('assignments.submission_status' => Mumuki::Domain::Status::Submission::Passed.to_i) },
           through: :assignments,
           class_name: 'Exercise',
           source: :exercise

  belongs_to :last_exercise, class_name: 'Exercise', optional: true
  belongs_to :last_organization, class_name: 'Organization', optional: true

  has_one :last_guide, through: :last_exercise, source: :guide

  has_many :exam_authorizations

  has_many :exams, through: :exam_authorizations

  enum gender: %i(female male other unspecified)
  belongs_to :avatar, optional: true

  before_validation :set_uid!
  validates :uid, presence: true

  after_initialize :init
  PLACEHOLDER_IMAGE_URL = 'user_shape.png'.freeze

  resource_fields :uid, :social_id, :email, :permissions, :verified_first_name, :verified_last_name, *profile_fields

  def last_lesson
    last_guide.try(:lesson)
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

  def unread_messages
    messages.where read: false
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

  def verify_name!
    self.verified_first_name ||= first_name
    self.verified_last_name ||= last_name
    save!
  end

  def unsubscribe_from_reminders!
    update! accepts_reminders: false
  end


  def attach!(role, course)
    add_permission! role, course.slug
    save_and_notify!
  end

  def detach!(role, course)
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

  def current_audience
    current_organic_context&.target_audience
  end

  def placeholder_image_url
    PLACEHOLDER_IMAGE_URL
  end

  private

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

  def self.unsubscription_verifier
    Rails.application.message_verifier(:unsubscribe)
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

  def current_organic_context
    if Organization.current?
      Organization.current
    else
      main_organization
    end
  end
end
