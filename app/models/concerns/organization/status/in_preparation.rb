class Organization::Status::InPreparation < Organization::Status::Base

  def teacher_access_mode(user)
    OrganizationAccessMode::Full.new user, organization
  end

  def student_access_mode(user)
    OrganizationAccessMode::ComingSoon.new user, organization
  end

  def ex_student_access_mode(user)
    OrganizationAccessMode::ReadOnly.new user, organization, :faqs, :profile
  end

  def outsider_access_mode(user)
    if organization.public?
      OrganizationAccessMode::ComingSoon.new user, organization
    else
      OrganizationAccessMode::Forbidden.new user, organization
    end
  end

  def validate_enabled!
    raise Mumuki::Domain::UnpreparedOrganizationError
  end
end
