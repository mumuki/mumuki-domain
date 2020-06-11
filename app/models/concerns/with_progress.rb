module WithProgress
  def progress_for(user, organization)
    Indicator.find_or_initialize_by(user: user, organization: organization, content: self)
  end

  def completion_ratio_for(user, organization=Organization.current)
    progress_for(user, organization).completion_ratio
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

  def completed_for?(user, organization, ratio: 1)
    progress = progress_for(user, organization)
    ratio == 1 ? progress.completed? : completion_ratio > ratio
  end

  private

  def structural_children_changed?(old_structural_children)
    (Set.new(structural_children) ^ Set.new(old_structural_children)).present?
  end
end
