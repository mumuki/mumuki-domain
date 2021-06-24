class OrganizationAccessMode::Full < OrganizationAccessMode::Base
  def profile_here?
    true
  end

  def submit_solutions_here?
    true
  end

  def validate_discuss_here?(_discussion)
  end

  def show_discussion_element?
    true
  end
end