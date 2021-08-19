module WithProgress
  def progress_for(user, organization)
    user.progress_at(self, organization)
  end

  def completion_percentage_for(user, organization=Organization.current)
    progress_for(user, organization).completion_percentage
  end

  def has_progress_for?(user, organization)
    progress_for(user, organization).persisted?
  end

  def dirty_progresses!
    Indicator.dirty_by_content_change! self
  end

  def dirty_progress_if_structural_children_changed!
    old_structural_children = structural_children.to_a
    yield
    Indicator.dirty_by_content_change! self if structural_children_changed?(old_structural_children)

    self
  end

  def completed_for?(user, organization)
    progress_for(user, organization).completed?
  end

  def once_completed_for?(user, organization)
    progress_for(user, organization).once_completed?
  end

  private

  def structural_children_changed?(old_structural_children)
    (Set.new(structural_children) ^ Set.new(old_structural_children)).present?
  end
end
