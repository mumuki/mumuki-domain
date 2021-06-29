module WithReminders
  extend ActiveSupport::Concern
  include WithPgLock

  def build_reminder
    mailer = UserMailer.new
    last_submission_date.nil? ?
      mailer.no_submissions_reminder(self) :
      mailer.we_miss_you_reminder(self, cycles_since(last_submission_date))
  end

  def remind!
    build_reminder.deliver_now
    update! last_reminded_date: Time.current
  end

  def should_remind?
    reminder_due? && (has_no_submissions? || has_no_recent_submission?)
  end

  # Try to send a reminder, by acquiring a database lock for update
  # the appropriate record. This object can't be updated as long as
  # the reminder is being sent.
  #
  # This method is aimed to be sent across multiple servers or processed concurrently
  # and still not send duplicate mails
  def try_remind_with_lock!
    with_pg_lock proc { remind! }, proc { should_remind? }
  end

  private

  def cycles_since(time)
    ((Date.current - time.to_date) / self.class.reminder_frequency).to_i
  end

  def reminder_due?
    last_reminded_date.nil? || cycles_since(last_reminded_date) >= 1
  end

  def can_still_remind?(date)
    cycles_since(date).between?(1, 3)
  end

  def has_no_submissions?
    last_submission_date.nil? && can_still_remind?(created_at)
  end

  def has_no_recent_submission?
    !last_submission_date.nil? && can_still_remind?(last_submission_date)
  end

  module ClassMethods
    def remindable
      where('accepts_reminders  and email is not null
                                and last_organization_id is not null
                                and (last_submission_date < ? or last_submission_date is null)', reminder_frequency.days.ago)
    end

    # The frequency of reminders, expressed in days
    def reminder_frequency
      Rails.configuration.reminder_frequency
    end
  end
end
