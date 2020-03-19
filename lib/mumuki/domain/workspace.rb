class OrganizationWorkspace
  def initialize(user, organization)
    @user = user
    @organization = organization
  end

  def audit(content)
    Mumuki::Domain::Access::Level.min @organization.access_rules.map { |it| it.call content, self }
  end

  def access_levels_for(contents)
    contents.map { |it| [it, audit(it)] }.to_h
  end

  def has_role?(role)
    @user.has_permission? role, @organization.slug
  end
end


class CourseWorkspace

end
