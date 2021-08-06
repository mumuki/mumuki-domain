class OrganizationAccessMode::ComingSoon < OrganizationAccessMode::Forbidden
  def validate_active!
    raise Mumuki::Domain::UnpreparedOrganizationError
  end
end
