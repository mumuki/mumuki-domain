class MassiveJob < ApplicationRecord

  belongs_to :target, polymorphic: true
  belongs_to :user

  has_many :massive_job_failed_items

  delegate :organization, :description, to: :target
  delegate :uid, :email, :formal_full_name, to: :user

  alias_attribute :failed_items, :massive_job_failed_items

  def friendly
    description
  end

  def subject
    target_type.constantize.subject
  end

  def notify_creation!(uids)
    Mumukit::Nuntius.notify_job! 'MassiveJobCreated', massive_job_id: id, uids: uids
  end

  def notify_users_to_add!(uids)
    uids.each do |uid|
      Mumukit::Nuntius.notify_job! 'UserAddedMassiveJob', massive_job_id: id, uid: uid
    end
  end

  def process!(uid)
    user = User.locate!(uid)
    return if target.processed? user
    target.process! user
    increment_processed_count!
  rescue => error
    increment_failed_count! uid, error
  end

  def status
    return :pending if total.zero?
    return :passed if processed_count == total_count
    return :failed if total == total_count
    :processing
  end

  def icon
    case status
    when :pending
      { class: 'fa-hourglass', type: 'info' }
    when :passed
      { class: 'fa-check-circle', type: 'success' }
    when :failed
      { class: 'fa-times-circle', type: 'danger' }
    else
      { class: 'fa-circle-notch fa-spin', type: 'warning' }
    end
  end

  def total
    processed_count + failed_count
  end

  def percentage
    total * 100 / total_count
  end

  def organization_name
    organization.name
  end

  private

  def increment_processed_count!
    increment! :processed_count
  end

  def increment_failed_count!(uid, error)
    transaction do
      increment! :failed_count
      failed_items.create! uid: uid, message: error.message, stacktrace: error.full_message(highlight: false, order: :top)
    end
  end

  class << self
    def process!(massive_job_id, uid)
      MassiveJob.find(massive_job_id).process!(uid)
    end

    def notify_users_to_add!(massive_job_id, uids)
      MassiveJob.find(massive_job_id).notify_users_to_add!(uids)
    end
  end
end
