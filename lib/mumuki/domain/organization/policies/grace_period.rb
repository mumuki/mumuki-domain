class Mumuki::Domain::Organization::EmailVerificationPolicy::GracePeriod < Mumuki::Domain::Organization::EmailVerificationPolicy
  attr_reader :grace_period

  def initialize(options)
    @grace_period = options[:period]
  end

  def verify!(user)
    raise GracePeriodStartError unless user.verification_requested_date
    super
  end

  def meets_policy?(user)
    Time.now - user.verification_requested_date < grace_period
  end
end
