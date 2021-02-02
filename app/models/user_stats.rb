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
    {
        exercises: {
            solved_count: organization_exercises
                              .joins(:assignments)
                              .where(assignments: { top_submission_status: [:passed, :skipped], submitter: user }.merge_if_present(:submitted_at, date_range))
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
    Message.joins(:discussion)
        .where({sender: user.uid, discussions: { organization: organization }}.merge_if_present(:date, date_range))
  end

  def organization_exercises
    organization.book.exercises
  end
end

class Hash
  def merge_if_present(key, value)
    value ? merge({ key => value }) : self
  end
end
