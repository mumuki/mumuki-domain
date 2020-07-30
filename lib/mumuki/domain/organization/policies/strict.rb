class Mumuki::Domain::Organization::EmailVerificationPolicy::Strict < Mumuki::Domain::Organization::EmailVerificationPolicy
  def meets_policy?(_user)
    false
  end
end
