class Chapter < ApplicationRecord
  include WithStats
  include WithNumber

  include SiblingsNavigation
  include TerminalNavigation

  include FriendlyName

  include TopicContainer

  belongs_to :book, optional: true

  has_many :exercises, through: :topic

  delegate :mono_lesson?, :mono_lesson, :first_lesson, to: :topic

  delegate :next_exercise, :stats_for, to: :mono_lesson, allow_nil: true

  def used_in?(organization)
    organization.book == self.book
  end

  def index_usage!(organization = Organization.current)
    organization.index_usage_of! topic, self
    lessons.each { |lesson| lesson.index_usage! organization }
  end

  def structural_parent
    book
  end

  def pending_siblings_for(user)
    book.pending_chapters(user)
  end
end
