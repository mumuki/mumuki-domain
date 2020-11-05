module WithTermsAcceptance
  def has_forum_terms_to_accept?
    !has_accepted_all?(forum_terms)
  end

  def has_profile_terms_to_accept?
    !has_accepted_all?(profile_terms)
  end

  def forum_terms
    @forum_terms ||= Term.forum_related_terms
  end

  def profile_terms
    @profile_terms ||= Term.profile_terms_for(self)
  end

  def accept_profile_terms!
    accept_terms! profile_terms
  end

  def accept_forum_terms!
    accept_terms! forum_terms
  end

  def has_accepted?(term)
    term_accepted_at_for(term.scope).try { |it| it > term.updated_at }.present?
  end

  private

  def unaccepted_terms_in(terms)
    terms.reject { |term| has_accepted? term}
  end

  def unaccepted_terms_scopes_in(terms)
    unaccepted_terms_in(terms).map(&:scope)
  end

  def has_accepted_all?(terms)
    unaccepted_terms_in(terms).blank?
  end

  def term_accepted_at_for(role)
    send term_acceptance_field_for(role)
  end

  def term_acceptance_field_for(role)
    "#{role}_terms_accepted_at"
  end

  def accept_terms!(terms)
    update! unaccepted_terms_scopes_in(terms).to_h { |scope| [term_acceptance_field_for(scope), Time.now] }
  end

end

