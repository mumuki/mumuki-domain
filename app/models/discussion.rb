class Discussion < ApplicationRecord
  include WithDiscussionStatus, WithScopedQueries, Contextualization

  belongs_to :item, polymorphic: true
  has_many :messages, -> { order(:created_at) }, dependent: :destroy
  belongs_to :initiator, class_name: 'User'
  belongs_to :exercise, foreign_type: :exercise, foreign_key: 'item_id'
  belongs_to :organization
  has_many :subscriptions
  has_many :upvotes

  scope :by_language, -> (language) { includes(:exercise).joins(exercise: :language).where(languages: {name: language}) }
  scope :order_by_responses_count, -> (direction) { reorder(validated_messages_count: direction, messages_count: opposite(direction)) }
  scope :by_requires_moderator_response, -> (boolean) { where(requires_moderator_response: boolean.to_boolean) }

  after_create :subscribe_initiator!

  markdown_on :description

  sortable :responses_count, :upvotes_count, :created_at, default: :created_at_desc
  filterable :status, :language, :requires_moderator_response
  pageable

  delegate :language, to: :item
  delegate :to_discussion_status, to: :status

  scope :for_user, -> (user) do
    if user.try(:moderator_here?)
      all
    else
      where.not(status: :closed).where.not(status: :pending_review).or(where(initiator: user))
    end
  end

  def try_solve!
    if opened?
      update! status: reachable_statuses_for(initiator).first
    end
  end

  def used_in?(organization)
    organization == self.organization
  end

  def commentable_by?(user)
    user&.moderator_here? || (opened? && user.present?)
  end

  def subscribable?
    opened? || solved?
  end

  def has_submission?
    submission.solution.present?
  end

  def read_by?(user)
    subscription_for(user).read
  end

  def last_message_date
    messages.last&.created_at || created_at
  end

  def friendly
    initiator.name
  end

  def subscription_for(user)
    subscriptions.find_by(user: user)
  end

  def upvote_for(user)
    upvotes.find_by(user: user)
  end

  def unread_subscriptions(user)
    subscriptions.where.not(user: user).map(&:unread!)
  end

  def submit_message!(message, user)
    message.merge!(sender: user.uid)
    messages.create(message)
    user.subscribe_to! self
    unread_subscriptions(user)
  end

  def authorized?(user)
    initiator?(user) || user.try(:moderator_here?)
  end

  def initiator?(user)
    user.try(:uid) == initiator.uid
  end

  def reachable_statuses_for(user)
    return [] unless authorized?(user)
    status.reachable_statuses_for(user, self)
  end

  def reachable_status_for?(user, status)
    reachable_statuses_for(user).include? status
  end

  def allowed_statuses_for(user)
    status.allowed_statuses_for(user, self)
  end

  def update_status!(status, user)
    update!(status: status) if reachable_status_for?(user, status)
  end

  def has_messages?
    messages.exists? || description.present?
  end

  def responses_count
    messages.where.not(sender: initiator.uid).count
  end

  def has_responses?
    responses_count > 0
  end

  def subscribe_initiator!
    initiator.subscribe_to! self
  end

  def extra_preview_html
    # FIXME this is buggy, because the extra
    # may have changed since the submission of this discussion
    exercise.assignment_for(initiator).extra_preview_html
  end

  def update_counters_and_timestamps!
    messages_query = messages_by_updated_at
    validated_messages = messages_query.select &:validated?
    update! messages_count: messages_query.count,
            validated_messages_count: validated_messages.count,
            last_initiator_message_at: messages_query.find(&:from_initiator?)&.updated_at,
            last_moderator_message_at: validated_messages.first&.updated_at
  end

  def update_requires_moderator_response!
    requires_moderator_response = messages_by_updated_at.find { |it| it.validated? || it.question? }&.from_initiator?
    update! requires_moderator_response: requires_moderator_response
  end

  def self.debatable_for(klazz, params)
    debatable_id = params[:"#{klazz.underscore}_id"]
    klazz.constantize.find(debatable_id)
  end

  private

  def messages_by_updated_at(direction = :desc)
    messages.reorder(updated_at: direction)
  end
end
