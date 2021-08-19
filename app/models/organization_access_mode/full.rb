class OrganizationAccessMode::Full < OrganizationAccessMode::Base
  def profile_here?
    true
  end

  def submit_solutions_here?
    true
  end

  def show_discussion_element?
    true
  end

  def resolve_discussions_here?
    discuss_here?
  end

  def validate_discuss_here!(_discussion)
  end

  def show_content?(_content)
    true
  end

  def show_content_element?
    true
  end
end