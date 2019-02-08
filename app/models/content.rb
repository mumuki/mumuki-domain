class Content < ApplicationRecord
  self.abstract_class = true

  include Syncable
  include WithDescription
  include WithLocale
  include WithSlug
  include WithUsages
  include WithName

  def to_resource_h
    as_json(only: [:name, :slug, :description, :locale]).symbolize_keys
  end

  def fork_to!(organization, syncer, quiet: false)
    rebased_dup(organization).tap do |dup|
      next if quiet && self.class.exists?(slug: dup.slug)

      fork_children_into! dup, organization, syncer
      dup.save!
      syncer.export! dup
    end
  end
end

