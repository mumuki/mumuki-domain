class UserStats < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  def self.stats_for(user)
    UserStats.find_or_initialize_by(user: user, organization: Organization.current)
  end

  def self.exp_for(user)
    self.stats_for(user).exp
  end

  def activity(date_range = nil)
    date_filter = { updated_at: date_range }.compact
    {
        exercises: {
            solved_count: organization_exercises
                              .joins(:assignments)
                              .where(assignments: { top_submission_status: [:passed, :skipped], submitter: user, organization: organization }.merge(date_filter))
                              .count,
            count: organization_exercises.count
        },
        messages: messages_in_discussions_count(date_range)
    }
  end

  def add_exp!(points)
    self.exp += points
  end

  private

  def messages_in_discussions_count(date_range = nil)
    date_filter = { created_at: date_range }.compact
    result = Message.joins(:discussion)
        .where({sender: user.uid, deletion_motive: nil, discussions: { organization: organization }}.merge(date_filter))
        .group(:approved)
        .count
    unapproved = result[false] || 0
    approved = result[true] || 0

    { count: unapproved + approved, approved: approved }
  end

  def organization_exercises
    @organization_exercises ||= organization.exercises
  end
end
