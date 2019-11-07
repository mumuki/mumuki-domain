class Content < ApplicationRecord
  self.abstract_class = true

  include Mumuki::Domain::Syncable
  include WithDescription
  include WithLocale
  include WithSlug
  include WithUsages
  include WithName

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

  def progress_for(user, organization=Organization.current)
    Indicator.find_or_initialize_by(user: user, organization: organization, content: self)
  end
end
