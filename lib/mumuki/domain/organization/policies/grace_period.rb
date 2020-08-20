class Mumuki::Domain::Organization::EmailVerificationPolicy::GracePeriod < Mumuki::Domain::Organization::EmailVerificationPolicy
  def verify!(user)
    raise GracePeriodStartError unless user.verification_requested_date
    super
  end

  def meets_policy?(user)
    Time.now - user.verification_requested_date < options.grace_period
  end
end
