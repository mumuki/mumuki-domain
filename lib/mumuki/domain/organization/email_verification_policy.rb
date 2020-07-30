class Mumuki::Domain::Organization::EmailVerificationPolicy
  def self.parse(policy)
    return Mumuki::Domain::Organization::EmailVerificationPolicy::Lax.new unless policy
    "Mumuki::Domain::Organization::EmailVerificationPolicy::#{policy[:type].capitalize}".constantize.new(policy[:options])
  end

  def initialize(*)
  end

  def verify!(user)
    raise MustVerifyEmailError unless user.email_verified? || meets_policy?(user)
  end
end

require_relative 'policies/lax'
require_relative 'policies/strict'
require_relative 'policies/grace_period'
