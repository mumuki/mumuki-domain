class Discussion < ApplicationRecord
  include WithDiscussionStatus, WithScopedQueries, Contextualization, WithResponsibleModerator

  belongs_to :item, polymorphic: true
  has_many :messages, -> { order(:created_at) }, dependent: :destroy
  belongs_to :initiator, class_name: 'User'

  belongs_to :responsible_moderator_by, class_name: 'User', optional: true
  belongs_to :status_updated_by, class_name: 'User', optional: true

  belongs_to :exercise, foreign_type: :exercise, foreign_key: 'item_id'
  belongs_to :organization
  has_many :subscriptions
  has_many :upvotes

  scope :by_language, -> (language) { includes(:exercise).joins(exercise: :language).where(languages: {name: language}) }
  scope :order_by_responses_count, -> (direction) { reorder(validated_messages_count: direction, messages_count: opposite(direction)) }
  scope :by_requires_attention, -> (boolean) { opened_and_requires_moderator_response(boolean).or(pending_review).no_responsible_moderator }
  scope :opened_and_requires_moderator_response, -> (boolean) { where(requires_moderator_response: boolean.to_boolean)
                                                                  .where(status: :opened) }
  scope :no_responsible_moderator, -> { where('responsible_moderator_at < ?', Time.now - MODERATOR_MAX_RESPONSIBLE_TIME)
                                          .or(where(responsible_moderator_at: nil)) }
  scope :pending_review, -> { where(status: :pending_review) }
  scope :unread_first, -> { (includes(:subscriptions).reorder('subscriptions.read')) }

  after_create :subscribe_initiator!

  markdown_on :description

  sortable :responses_count, :upvotes_count, :created_at, default: :created_at_desc
  filterable :status, :language, :requires_attention
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

  def visible_messages
    messages.visible
  end

  def try_solve!
    if opened?
      update! status: reachable_statuses_for(initiator).first
    end
  end

  def navigable_content_in(_)
    nil
  end

  def target
    self
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
    visible_messages.last&.created_at || created_at
  end

  def friendly
    initiator.abbreviated_name
  end

  def subscription_for(user)
    subscriptions.find_by(user: user)
  end

  def upvote_for(user)
    upvotes.find_by(user: user)
  end

  def mark_subscriptions_as_unread!(user)
    subscriptions.where.not(user: user).map(&:unread!)
  end

  def submit_message!(message, user)
    message.merge!(sender: user.uid)
    messages.create(message)
    user.subscribe_to! self
    mark_subscriptions_as_unread!(user)
    no_responsible! if responsible?(user)
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

  def update_status!(status, user)
    if reachable_status_for?(user, status)
      update! status: status,
              status_updated_by: user,
              status_updated_at: Time.current

      no_responsible! if responsible?(user)
    end
  end

  def has_messages?
    visible_messages.exists? || description.present?
  end

  def responses_count
    visible_messages.where.not(sender: initiator.uid).count
  end

  def has_responses?
    responses_count > 0
  end

  def has_validated_responses?
    validated_messages_count > 0
  end

  def requires_attention_for?(user)
    user&.moderator_here? && requires_attention?
  end

  def requires_attention?
    no_current_responsible? && status.requires_attention_for?(self)
  end

  def subscribe_initiator!
    initiator.subscribe_to! self
  end

  def extra_preview_html
    # FIXME this is buggy, because the extra
    # may have changed since the submission of this discussion
    exercise.assignment_for(initiator).extra_preview_html
  end

  def update_counters!
    messages_query = messages_by_updated_at
    validated_messages = messages_query.select &:validated?
    has_moderator_response = messages_query.find { |it| it.validated? || it.question? }&.validated?
    update! messages_count: messages_query.count,
            validated_messages_count: validated_messages.count,
            requires_moderator_response: !has_moderator_response
  end

  def self.debatable_for(klazz, params)
    debatable_id = params[:"#{klazz.underscore}_id"]
    klazz.constantize.find(debatable_id)
  end

  private

  def messages_by_updated_at(direction = :desc)
    messages.where(deletion_motive: nil).reorder(updated_at: direction)
  end
end
