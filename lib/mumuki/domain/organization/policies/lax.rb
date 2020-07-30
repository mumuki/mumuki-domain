class Mumuki::Domain::Organization::EmailVerificationPolicy::Lax < Mumuki::Domain::Organization::EmailVerificationPolicy
  def meets_policy?(_user)
    true
  end
end
