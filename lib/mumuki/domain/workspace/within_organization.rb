module Mumuki::Domain::Workspace
  class WithinOrganization
    def initialize(user, organization)
      @user = user
      @organization = organization
    end

    def has_role?(role)
      @user.has_permission? role, @organization.slug
    end
  end
end
