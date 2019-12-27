module WithUsages
  extend ActiveSupport::Concern

  included do
    has_many :usages, as: :item
    before_destroy :ensure_unused!
    organic_on :usages
  end

  def usage_in_organization(organization = Organization.current)
    usages_in_organization(organization).first.try(:parent_item)
  end

  def usage_in_organization_of_type(type, organization = Organization.current)
    item = usage_in_organization(organization)
    item.is_a?(type) ? item : nil
  end

  class_methods do
    def content_aggregate_of(association)
      aggregate_of association

      define_method :rebuild_with_usages! do |children|
        old_children = send association
        added_children = children - old_children
        rebuild! children
        usages.each { |it| it.index_children(added_children) }

        self
      end
    end
  end

  private

  def ensure_unused!
    if usages.present?
      errors.add :base, :in_use, organization: usages.first.organization.name
      throw :abort
    end
  end
end
