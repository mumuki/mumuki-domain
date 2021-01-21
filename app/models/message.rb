class Message < ApplicationRecord

  belongs_to :discussion, optional: true
  belongs_to :assignment, foreign_key: :submission_id, primary_key: :submission_id, optional: true
  has_one :exercise, through: :assignment

  validates_presence_of :content, :sender
  validates_presence_of :submission_id, :unless => :discussion_id?

  after_save :update_counters_cache!
  after_destroy :update_counters_cache!

  markdown_on :content

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
    as_json(except: [:id, :type, :discussion_id, :approved, :not_actually_a_question],
            include: {exercise: {only: [:bibliotheca_id]}})
        .merge(organization: Organization.current.name)
  end

  def read!
    update! read: true
  end

  def toggle_approved!
    toggle! :approved
  end

  def toggle_not_actually_a_question!
    toggle! :not_actually_a_question
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

  def self.parse_json(json)
    message = json.delete 'message'
    json
        .except('uid', 'exercise_id')
        .merge(message)
  end

  def self.read_all!
    update_all read: true
  end

  def self.import_from_resource_h!(json)
    message_data = parse_json json
    Organization.find_by!(name: message_data.delete('organization')).switch!

    if message_data['submission_id'].present?
      Assignment.find_by(submission_id: message_data.delete('submission_id'))&.receive_answer! message_data
    end
  end
end
