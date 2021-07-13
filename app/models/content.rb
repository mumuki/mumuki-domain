class Content < ApplicationRecord
  self.abstract_class = true

  include Mumuki::Domain::Syncable
  include WithDescription
  include WithLocale
  include WithMedal
  include WithName
  include WithProgress
  include WithSlug
  include WithUsages

  def to_resource_h(*args)
    to_expanded_resource_h(*args).compact
  end

  def to_expanded_resource_h(*)
    as_json(only: [:name, :slug, :description, :locale]).symbolize_keys
  end

  def fork_to!(organization, syncer, quiet: false)
    rebased_dup(organization).tap do |dup|
      self.class.find_by(slug: dup.slug).try { |it| return it } if quiet

      dup.validate!
      fork_children_into! dup, organization, syncer
      dup.save validate: false

      syncer.export! dup
    end
  end

  def public?
    !private?
  end

  def contextualize_for(_scope, _user, _organization)
    scope
  end
end
