class Message < ApplicationRecord
  include WithSoftDeletion

  belongs_to :discussion, optional: true
  belongs_to :assignment, optional: true
  belongs_to :approved_by, class_name: 'User', optional: true
  belongs_to :sender, class_name: 'User'

  has_one :exercise, through: :assignment

  validates_presence_of :content
  validate :ensure_contextualized

  before_create :mark_from_moderator!
  after_save :update_counters_cache!

  markdown_on :content

  # Visible messages are those that can be publicly seen
  # in forums. Direct messages are never visible.
  scope :visible, -> () do
    where.not(deletion_motive: :self_deleted)
      .or(where(deletion_motive: nil))
      .where(assignment_id: nil)
  end

  def contextualization
    direct? ? assignment : discussion
  end

  def contextualized?
    assignment_id.present? ^ discussion_id.present?
  end

  # Whether this message is stale, that is, it
  # targets a submission that is not the latest one.
  #
  # Only direct messages may become stale.
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
    sender == discussion&.initiator
  end

  def from_moderator?
    from_moderator || sender.moderator_here?
  end

  def from_user?(user)
    sender == user
  end

  def authorized?(user)
    from_user?(user) || user&.moderator_here?
  end

  def authorize!(user)
    raise Mumukit::Auth::UnauthorizedAccessError unless authorized?(user)
  end

  def to_resource_h
    as_json(except: [:id, :type, :discussion_id, :approved, :approved_at, :approved_by_id,
                     :not_actually_a_question, :deletion_motive, :deleted_at, :deleted_by_id,
                     :from_moderator, :sender_id],
            include: {exercise: {only: [:bibliotheca_id]}})
        .merge(organization: Organization.current.name, sender: sender.uid)
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

  def mark_from_moderator!
    self.from_moderator = from_moderator?
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
    if resource_h['submission_id'].present?
      assignment = Assignment.find_by(submission_id: resource_h['submission_id'])
      assignment&.receive_answer! sender: User.locate!(resource_h['message']['sender']),
                                  content: resource_h['message']['content']
    end
  end

  # TODO remove this once messages generate notifications
  def subject
    'message'
  end

  def sender
    super || User.locate!(self[:sender])
  end

  private

  def approve!(user)
    update! approved: true, approved_at: Time.current, approved_by: user
  end

  def disapprove!
    update! approved: false, approved_at: nil, approved_by: nil
  end

  def ensure_contextualized
    errors.add(:base, :not_properly_contextualized) unless contextualized?
  end
end
