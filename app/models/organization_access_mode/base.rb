class OrganizationAccessMode::Base
  attr_reader :user, :organization

  def initialize(user, organization)
    @user = user
    @organization = organization
  end

  def validate_active!
  end

  def faqs_here?
    organization.faqs.present?
  end

  def submit_solutions_here?
    false
  end

  def resolve_discussions_here?
    false
  end

  def discuss_here?
    organization.forum_enabled? && user.discusser_of?(organization) &&
      user.trusted_as_discusser_in?(organization) && !user.banned_from_forum? &&
      !user.currently_in_exam?
  end

  def show_discussion_element?
    false
  end

  def show_content_element?
    false
  end

  def restore_indicators?(_content)
    false
  end

  def read_only?
    false
  end

  def validate_discuss_here!(_discussion)
    raise Mumuki::Domain::ForbiddenError
  end

  def validate_content_here!(content)
    raise Mumuki::Domain::ForbiddenError unless show_content?(content)
  end
end

