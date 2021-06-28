class WithOrganizationStatus::Enabled < WithOrganizationStatus::Base

  def teacher_access_mode(user)
    OrganizationAccessMode::Full.new user, organization
  end

  def student_access_mode(user)
    OrganizationAccessMode::Full.new user, organization
  end

  def ex_student_access_mode(user)
    OrganizationAccessMode::ReadOnly.new user, organization, :faqs, :profile, :discussions, exercises: :submitted
  end

  def outsider_access_mode(user)
    OrganizationAccessMode::Forbidden.new user, organization
  end

  def validate!(_user = nil)
  end

end