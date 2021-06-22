class OrganizationAccessMode::Full < OrganizationAccessMode::Base
  def profile_here?
    true
  end

  def submit_solutions_here?
    true
  end
end