class Mumuki::Domain::Organization::EmailVerificationPolicy
  TYPES = %i(lax strict grace_period)

  attr_reader :options

  def self.parse(policy)
    return Mumuki::Domain::Organization::EmailVerificationPolicy::Lax.new unless policy
    "Mumuki::Domain::Organization::EmailVerificationPolicy::#{policy[:type].as_module_name}".constantize.new(policy[:options])
  end

  def initialize(options = {})
    @options = struct(options.to_h)
  end

  def verify!(user)
    raise Mumuki::Domain::MustVerifyEmailError unless user.email_verified? || meets_policy?(user)
  end

  def type
    self.class.name.demodulize.snakecase
  end
end

Mumuki::Domain::Organization::EmailVerificationPolicy::TYPES.each do |it|
  require_relative "policies/#{it}"
end
