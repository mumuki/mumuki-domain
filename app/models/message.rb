class Message < ApplicationRecord
  include WithSoftDeletion

  belongs_to :discussion, optional: true
  belongs_to :assignment, optional: true
  belongs_to :approved_by, class_name: 'User', optional: true

  has_one :exercise, through: :assignment

  validates_presence_of :content, :sender
  validate :contextualized?

  after_save :update_counters_cache!

  markdown_on :content

  # Visible messages are those that can be publicly seen
  # in forums. non-direct messages are naver visible.
  scope :visible, -> () do
    where.not(deletion_motive: :self_deleted)
      .or(where(deletion_motive: nil))
      .where(submission_id: nil)
  end

  def contextualization
    direct? ? assignment : discussion
  end

  def contextualized?
    assignment_id.present? ^ discussion_id.present?
  end

  # Whether this message is stale, that is,
  # targets a submission that is the latest one.
  #
  # This can occur only in direct messages.
  def stale?
    direct? && assignment.submission_id != submission_id
  end

  # Whether this message is direct, that is, whether it comes from rise-hand feature.
  # Forum messages are non-direct.
  def direct?
    submission_id.present?
  end

  def notify!
    Mumukit::Nuntius.notify! 'student-messages', to_resource_h unless Organization.silenced?
  end

  def from_initiator?
    sender_user == discussion&.initiator
  end

  def from_moderator?
    sender_user.moderator_here?
  end

  def from_user?(user)
    sender_user == user
  end

  def sender_user
    User.find_by(uid: sender)
  end

  def authorized?(user)
    from_user?(user) || user&.moderator_here?
  end

  def authorize!(user)
    raise Mumukit::Auth::UnauthorizedAccessError unless authorized?(user)
  end

  def to_resource_h
    as_json(except: [:id, :type, :discussion_id, :approved, :approved_at, :approved_by_id,
                     :not_actually_a_question, :deletion_motive, :deleted_at, :deleted_by_id],
            include: {exercise: {only: [:bibliotheca_id]}})
        .merge(organization: Organization.current.name)
  end

  def read!
    update! read: true
  end

  def toggle_approved!(user)
    if approved?
      disapprove!
    else
      approve!(user)
    end
  end

  def toggle_not_actually_a_question!
    toggle! :not_actually_a_question
  end

  def approved?
    approved_at?
  end

  def validated?
    approved? || from_moderator?
  end

  def update_counters_cache!
    discussion&.update_counters!
  end

  def question?
    from_initiator? && !not_actually_a_question?
  end

  def target
    self
  end

  def self.read_all!
    update_all read: true
  end

  def self.import_from_resource_h!(resource_h)
    ## TODO AVOID SWITCH
    Organization.locate!(resource_h['organization']).switch!

    ## TODO find by assignment_id
    if resource_h['submission_id'].present?
      assignment = Assignment.find_by(submission_id: resource_h['submission_id'])
      assignment&.receive_answer! sender: resource_h['message']['sender'],
                                  content: resource_h['message']['content']
    end
  end

  private

  def approve!(user)
    update! approved: true, approved_at: Time.now, approved_by: user
  end

  def disapprove!
    update! approved: false, approved_at: nil, approved_by: nil
  end
end
