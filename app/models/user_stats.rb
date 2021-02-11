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
    date_filter = { submitted_at: date_range }.compact
    {
        exercises: {
            solved_count: organization_exercises
                              .joins(:assignments)
                              .where(assignments: { top_submission_status: [:passed, :skipped], submitter: user }.merge(date_filter))
                              .count,
            count: organization_exercises.count},

        messages: {
            count: messages_in_discussions(date_range).count,
            approved: messages_in_discussions(date_range).where(approved: true).count}
    }
  end

  def add_exp!(points)
    self.exp += points
  end

  private

  def messages_in_discussions(date_range = nil)
    date_filter = { date: date_range }.compact
    Message.joins(:discussion)
        .where({sender: user.uid, discussions: { organization: organization }}.merge(date_filter))
  end

  def organization_exercises
    organization.book.exercises
  end
end
