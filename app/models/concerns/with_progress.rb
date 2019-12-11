module WithProgress
  def progress_for(user, organization=Organization.current)
    Indicator.find_or_initialize_by(user: user, organization: organization, content: self)
  end

  def dirty_progresses!
    Indicator.dirty_for_content! self
  end
end
