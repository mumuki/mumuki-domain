class Usage < ApplicationRecord
  belongs_to :organization

  belongs_to :item, polymorphic: true
  belongs_to :parent_item, polymorphic: true

  scope :in_organization, ->(organization = Organization.current) { where(organization_id: organization.id) }

  before_save :set_slug
  before_destroy :destroy_children_usages!

  def self.destroy_all_where(query)
    where(query).destroy_all
  end

  def self.destroy_usages_for(record)
    destroy_all_where(parent_item: record)
  end

  def destroy_children_usages!
    item.children.each { |child| Usage.destroy_all_where(item: child, organization: organization) }
  end

  def index_children!(children)
    children.each { |it| it.index_usage! organization }
  end

  private

  def set_slug
    self.slug = item.slug
  end
end
