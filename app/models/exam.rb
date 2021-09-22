class Exam < ApplicationRecord

  include GuideContainer
  include FriendlyName
  include TerminalNavigation
  include WithTimedEnablement

  belongs_to :organization
  belongs_to :course

  has_many :authorizations, class_name: 'ExamAuthorization', dependent: :destroy
  has_many :authorization_requests, class_name: 'ExamAuthorizationRequest', dependent: :destroy
  has_many :users, through: :authorizations

  has_and_belongs_to_many :exam_registrations

  enum passing_criterion_type: [:none, :percentage, :passed_exercises], _prefix: :passing_criterion

  validates_presence_of :start_time, :end_time
  validates_numericality_of :max_problem_submissions, :max_choice_submissions, greater_than_or_equal_to: 1, allow_nil: true

  before_save :set_default_criterion_type!
  before_save :ensure_valid_passing_criterion!

  before_create :set_classroom_id!

  after_destroy { |record| Usage.destroy_usages_for record }
  after_create :reindex_usages!

  def used_in?(organization)
    organization == self.organization
  end

  def enabled_for?(user)
    enabled_range_for(user).cover? Time.current
  end

  def in_progress_for?(user)
    accessible_for?(user) && started?(user)
  end

  def validate_accessible_for!(user)
    if user.present?
      raise Mumuki::Domain::ForbiddenError unless authorized?(user)
      raise Mumuki::Domain::GoneError unless enabled_for?(user)
    else
      raise Mumuki::Domain::UnauthorizedError
    end
  end

  def accessible_for?(user)
    (authorized?(user) && enabled_for?(user)) || user&.teacher_here?
  end

  def timed?
    duration.present?
  end

  def authorize!(user)
    users << user unless authorized?(user)
  end

  def authorized?(user)
    users.include? user
  end

  def enabled_range_for(user)
    start_time..real_end_time(user)
  end

  def authorization_for(user)
    authorizations.find_by(user_id: user.id)
  end

  def authorizations_for(users)
    authorizations.where(user_id: users.map(&:id))
  end

  def start!(user)
    return if user.teacher_here?

    authorization = authorization_for(user)
    raise Mumuki::Domain::ForbiddenError unless authorization
    authorization.start!
  end

  def started?(user)
    authorization_for(user).try(:started?)
  end

  def real_end_time(user)
    if duration.present? && started?(user)
      [started_at(user) + duration.minutes, end_time].min
    else
      end_time
    end
  end

  def started_at(user)
    authorization_for(user).started_at
  end

  def authorize_users!(users)
    users.each { |user| authorize! user }
  end

  def unauthorize_users!(users)
    authorizations_for(users).destroy_all
  end

  def process_users(users)
    authorize_users!(users)
    clean_authorizations users
  end

  def clean_authorizations(authorized_users)
    unauthorize_users!(users.all_except(authorized_users))
  end

  def reindex_usages!
    index_usage! organization
  end

  def attempts_left_for(assignment)
    max_attempts_for(assignment.exercise) - (assignment.attempts_count || 0)
  end

  def limited_for?(exercise)
    max_attempts_for(exercise).present?
  end

  def results_hidden_for?(exercise)
    exercise.choice? && results_hidden_for_choices?
  end

  def resettable?
    false
  end

  def set_classroom_id!
    self.classroom_id ||= SecureRandom.hex(8)
  end

  def passing_criterion
    @passing_criterion ||= Exam::PassingCriterion.parse(passing_criterion_type, passing_criterion_value)
  end

  def ensure_valid_passing_criterion!
    passing_criterion.ensure_valid!
  end

  def set_default_criterion_type!
    self.passing_criterion_type ||= :none
  end

  def self.import_from_resource_h!(json)
    exam_data = json.with_indifferent_access
    Organization.locate!(exam_data[:organization].to_s).switch!
    adapt_json_values exam_data
    remove_previous_version exam_data[:eid], exam_data[:guide_id]
    exam = where(classroom_id: exam_data[:eid]).update_or_create!(whitelist_attributes(exam_data))
    exam.process_users exam_data[:users]
    exam
  end

  def self.upsert_students!(json)
    data = json.with_indifferent_access
    exam = find_by(classroom_id: data[:eid])

    added_users = User.where(uid: data[:added])
    deleted_users = User.where(uid: data[:deleted])

    exam.authorize_users! added_users
    exam.unauthorize_users! deleted_users
  end

  def self.adapt_json_values(exam)
    exam[:guide_id] = Guide.locate!(exam[:slug]).id
    exam[:organization_id] = Organization.current.id
    exam[:course_id] = Course.locate!(exam[:course].to_s).id
    exam[:users] = User.where(uid: exam[:uids])
    exam[:start_time] = exam[:start_time].in_time_zone
    exam[:end_time] = exam[:end_time].in_time_zone
    exam[:classroom_id] = exam[:eid] if exam[:eid].present?
  end

  def self.remove_previous_version(eid, guide_id)
    Rails.logger.info "Looking for"
    where("guide_id=? and organization_id=? and classroom_id!=?", guide_id, Organization.current.id, eid).tap do |exams|
      Rails.logger.info "Deleting exams with ORG_ID:#{Organization.current.id} - GUIDE_ID:#{guide_id} - CLASSROOM_ID:#{eid}"
      exams.destroy_all
    end
  end

  private

  def max_attempts_for(exercise)
    exercise.choice? ? max_choice_submissions : max_problem_submissions
  end

end
