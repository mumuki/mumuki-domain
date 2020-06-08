module Mumuki::Domain::Workspace
  class WithinOrganization
    attr_accessor :user, :organization

    def initialize(user, organization)
      @user = user
      @organization = organization
    end

    def has_role?(role)
      @user.has_permission? role, organization.slug
    end

    def annonymous?
      user.nil?
    end

    # Tells the enabled chapters for this user in this workspaces
    # This method does not check the user is actually member of the organization,
    # you should check that before sending this message
    def enabled_chapters(chapters_sequence)
      # TODO refactor when introducing access rules
      if !annonymous? && !has_role?(:teacher) && organization.progressive_display_lookahead
        chapters_sequence.take(organization.progressive_display_lookahead)
      else
        chapters_sequence
      end
    end
  end
end
