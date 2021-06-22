class OrganizationAccessMode::Forbidden < OrganizationAccessMode::Base
  def validate_active!
    raise Mumuki::Domain::ForbiddenError unless Organization.current.public? || !user
  end

  def faqs_here?
    false
  end

  def profile_here?
    false
  end
end
