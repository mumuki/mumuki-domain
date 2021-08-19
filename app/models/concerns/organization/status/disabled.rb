class Organization::Status::Disabled < Organization::Status::Base

  def teacher_access_mode(user)
    OrganizationAccessMode::Full.new user, organization
  end

  def student_access_mode(user)
    OrganizationAccessMode::ReadOnly.new user, organization, :faqs, :profile, :exercises, :discussions
  end

  def ex_student_access_mode(user)
    OrganizationAccessMode::ReadOnly.new user, organization, :faqs, :profile
  end

  def outsider_access_mode(user)
    if organization.public?
      OrganizationAccessMode::Gone.new user, organization
    else
      OrganizationAccessMode::Forbidden.new user, organization
    end
  end

  def validate!(user = nil)
    raise Mumuki::Domain::DisabledOrganizationError unless user
  end

end

