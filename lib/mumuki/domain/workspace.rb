class Mumuki::Domain::Workspace
  attr_accessor :user, :scope

  # Scope is a organization-like or course-like object
  # that can be converted into slugs, has chapters and access-rules information
  def initialize(user, scope)
    @user = user
    @scope = scope
  end

  def annonymous?
    user.nil?
  end

  def teacher?
    user.teacher_of? scope
  end

  # Takes a didactic sequence of chapters and retuns the enabled chapters for this user
  # in this workspace.
  #
  # This method does not check the user is actually member of the scope,
  # you should check that before sending this message
  #
  def enabled_chapters(chapters_sequence)
    return chapters_sequence if annonymous? || teacher?

    # TODO refactor when introducing access rules
    if scope.progressive_display_lookahead
      user.completed_containers_with_lookahead(chapters_sequence, scope, lookahead: scope.progressive_display_lookahead)
    else
      chapters_sequence
    end
  end
end
