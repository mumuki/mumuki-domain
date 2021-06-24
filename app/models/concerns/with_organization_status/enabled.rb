class WithOrganizationStatus::Enabled < WithOrganizationStatus::Base

  def teacher_access_mode(user)
    OrganizationAccessMode::Full.new(user)
  end

  def student_access_mode(user)
    OrganizationAccessMode::Full.new user
  end

  def ex_student_access_mode(user)
    OrganizationAccessMode::ReadOnly.new(user, :faqs, :profile, :discussions, exercises: :submitted)
  end

  def outsider_access_mode(user)
    OrganizationAccessMode::Forbidden.new user
  end

  def validate!(_user)
  end

end