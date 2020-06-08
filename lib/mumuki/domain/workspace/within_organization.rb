module Mumuki::Domain::Workspace
  class WithinOrganization
    attr_accessor :user, :organization

    def initialize(user, organization)
      @user = user
      @organization = organization
    end

    def has_role?(role)
      @user.has_permission? role, @organization.slug
    end

    def enabled_chapters(chapters_sequence)
      # TODO refactor when introducing access rules
      if user && organization.progressive_display_lookahead
        chapters_sequence.take(organization.progressive_display_lookahead)
      else
        chapters_sequence
      end
    end
  end
end
