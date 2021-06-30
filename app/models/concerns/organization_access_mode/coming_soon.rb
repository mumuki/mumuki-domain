class OrganizationAccessMode::ComingSoon < OrganizationAccessMode::Base
  def validate_active!
    raise Mumuki::Domain::UnpreparedOrganizationError
  end

  def faqs_here?
    false
  end

  def profile_here?
    false
  end

  def discuss_here?
    false
  end

  def show_content?(_content)
    false
  end
end
