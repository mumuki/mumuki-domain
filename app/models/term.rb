class Term < ApplicationRecord
  attribute :locale, :string, default: 'es'
  markdown_on :content

  GENERAL = %w(legal privacy student)
  ROLE_SPECIFIC = %w(headmaster janitor teacher)

  validates :locale, uniqueness: { scope: :scope }
  validates :content, :scope, :header, presence: true

  def self.terms_for(scope, locale)
    where(scope: scope, locale: locale)
  end

  def self.profile_terms_for(user, locale = I18n.locale)
    general_terms(locale) + role_specific_terms_for(user, locale)
  end

  def self.role_specific_terms_for(user, locale = I18n.locale)
    terms_for(current_role_terms_for(user), locale)
  end

  def self.general_terms(locale = I18n.locale)
    terms_for(GENERAL, locale)
  end

  def self.current_role_terms_for(user)
    return [] unless user.present?
    (user.any_granted_roles & ROLE_SPECIFIC).to_a
  end

  def accepted_by?(user)
    user.term_accepted_at_for(scope).try { |it| it > updated_at }.present?
  end
end
