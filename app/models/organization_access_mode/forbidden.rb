class OrganizationAccessMode::Forbidden < OrganizationAccessMode::Base
  def validate_active!
    raise Mumuki::Domain::ForbiddenError if organization.private? && user.present?
  end

  def faqs_here?
    false
  end

  def profile_here?
    false
  end

  def show_content?(_content)
    false
  end

end
