class ExamRegistration < ApplicationRecord
  include WithTimedEnablement
  include TerminalNavigation

  belongs_to :organization
  has_and_belongs_to_many :exams
  has_many :authorization_requests, class_name: 'ExamAuthorizationRequest'
  has_and_belongs_to_many :registrees, class_name: 'User'
  has_many :notifications, as: :target

  enum authorization_criterion_type: %i(none passed_exercises), _prefix: :authorization_criterion

  before_save :ensure_valid_authorization_criterion!

  delegate :meets_authorization_criteria?, :process_request!, :authorization_criteria_matcher, to: :authorization_criterion

  alias_attribute :name, :description

  scope :should_process, -> { where(processed: false).where(arel_table[:end_time].lt(Time.current)) }

  def authorization_criterion
    @authorization_criterion ||= ExamRegistration::AuthorizationCriterion.parse(authorization_criterion_type, authorization_criterion_value)
  end

  def ensure_valid_authorization_criterion!
    authorization_criterion.ensure_valid!
  end

  def notify_unnotified_registrees!
    unnotified_registrees.each { |registree| notify_registree! registree }
  end

  def unnotified_registrees?
    unnotified_registrees.exists?
  end

  def register_users!(users)
    users.each { |user| register! user }
  end

  def unnotified_registrees
    registrees.where.not(id: Notification.notified_users_ids_for(self, self.organization))
  end

  # Try to process authorization request, by acquiring a database lock for update
  # the appropriate record.
  #
  # This method is aimed to be sent across multiple servers or processed concurrently
  # and still not send duplicate mails
  def process_requests!
    with_pg_lock proc { process_authorization_requests! }, proc { !processed? }
  end

  def process_authorization_requests!
    authorization_requests.each do |it|
      process_request! it
      it.try_authorize!
    end
    update! processed: true
  end

  def authorization_request_for(user)
    authorization_requests.find_by(user: user) ||
      ExamAuthorizationRequest.new(exam_registration: self, organization: organization)
  end

  def register!(user)
    registrees << user unless registered?(user)
  end

  def registered?(user)
    registrees.include? user
  end

  def meets_criterion?(user)
    authorization_criterion.meets_criterion?(user, organization)
  end

  def available_exams
    return exams unless limited_authorization_requests?
    Exam.find authorization_requests_counts.select do |_, count|
      count <= authorization_requests_limit
    end.keys
  end

  def limited_authorization_requests?
    authorization_requests_limit.present?
  end

  def multiple_options?
    exams.count > 1
  end

  def ended?
    end_time.past?
  end

  private

  def notify_registree!(registree)
    Notification.create_and_notify_via_email! organization: organization, user: registree, subject: :exam_registration, target: self
  end

  def authorization_requests_counts
    authorization_requests.group(:exam).count
  end
end
