class Organization::Status::Enabled < Organization::Status::Base

  def teacher_access_mode(user)
    OrganizationAccessMode::Full.new user, organization
  end

  def student_access_mode(user)
    OrganizationAccessMode::Full.new user, organization
  end

  def ex_student_access_mode(user)
    OrganizationAccessMode::ReadOnly.new user, organization, :faqs, :profile, exercises: :submitted
  end

  def outsider_access_mode(user)
    if organization.public?
      OrganizationAccessMode::Full.new user, organization
    else
      OrganizationAccessMode::Forbidden.new user, organization
    end
  end

  def validate_enabled!
  end
end