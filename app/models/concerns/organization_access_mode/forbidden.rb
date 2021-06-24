class OrganizationAccessMode::Forbidden < OrganizationAccessMode::ComingSoon
  def validate_active!
    raise Mumuki::Domain::ForbiddenError unless organization.public? || !user
  end
end
