class ExamRegistration < ApplicationRecord
  include WithTimedEnablement
  include TerminalNavigation

  belongs_to :organization
  has_and_belongs_to_many :exams
  has_many :authorization_requests, class_name: 'ExamAuthorizationRequest', through: :exams

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

  def start!(users)
    users.each &method(:notify_user!)
  end

  def process_requests!
    authorization_requests.each do |it|
      process_request! it
      it.try_authorize!
    end
  end

  private

  def notify_user!(user)
    Notification.create! organization: organization, user: user, target: self
  end
end
