class WithOrganizationStatus::Disabled < WithOrganizationStatus::Base

  def teacher_access_mode(user)
    OrganizationAccessMode::Full.new(user)
  end

  def student_access_mode(user)
    OrganizationAccessMode::ReadOnly.new(user, :faqs, :profile, :exercises, :discussions)
  end

  def ex_student_access_mode(user)
    OrganizationAccessMode::ReadOnly.new(user, :faqs, :profile)
  end

  def outsider_access_mode(user)
    OrganizationAccessMode::Forbidden.new user
  end

  def validate!(user)
    raise Mumuki::Domain::DisabledError unless user
  end

end

