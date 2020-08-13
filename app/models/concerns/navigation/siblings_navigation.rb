module SiblingsNavigation

  def next_for(user)
    user.pending_siblings_at(self).select { |it| it.number > number }.sort_by(&:number).first
  end

  def restart(user)
    user.pending_siblings_at(self).sort_by(&:number).first
  end

  def siblings
    structural_parent.structural_children
  end

  #TODO reestablish this after indicators reliably linked to assignments
  # def pending_siblings_for(user, organization=Organization.current)
  #   siblings.reject { |it| it.progress_for(user, organization).completed? }
  # end

  # Names

  def navigable_name
    "#{number}. #{name}"
  end

  # Answers a - maybe empty - list of pending siblings for the given user
  #required :pending_siblings_for
end
