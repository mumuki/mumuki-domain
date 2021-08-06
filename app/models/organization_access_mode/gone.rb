class OrganizationAccessMode::Gone < OrganizationAccessMode::Forbidden
  def validate_active!
    raise Mumuki::Domain::DisabledOrganizationError
  end
end
