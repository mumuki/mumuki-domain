module WithProgress
  def progress_for(user, organization)
    Indicator.find_or_initialize_by(user: user, organization: organization, content: self)
  end

  def completion_percentage_for(user, organization=Organization.current)
    progress_for(user, organization).completion_percentage
  end

  def dirty_progresses!
    Indicator.dirty_by_content_change! self
  end

  def dirty_progress_if_children_changed!
    old_children = children.to_a
    yield
    Indicator.dirty_by_content_change! self if children_changed?(old_children)

    self
  end

  private

  def children_changed?(old_children)
    (Set.new(children) ^ Set.new(old_children)).present?
  end
end
