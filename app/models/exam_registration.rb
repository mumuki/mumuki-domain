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

  delegate :meets_authorization_criteria?, :process_request!, to: :authorization_criterion

  alias_attribute :name, :description

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

  def process_requests!
    authorization_requests.each do |it|
      process_request! it
      it.try_authorize!
    end
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

  private

  def notify_registree!(registree)
    Notification.create! organization: organization, user: registree, target: self
  end
end
