module WithProgress
  def progress_for(user, organization)
    Indicator.find_or_initialize_by(user: user, organization: organization, content: self)
  end

  def completion_percentage_for(user, organization=Organization.current)
    progress_for(user, organization).completion_percentage
  end

  def dirty_progresses!
    Indicator.dirty_for_content! self
  end
end
