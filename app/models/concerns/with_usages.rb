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

  def used_in?(organization)
    usage_in_organization(organization).present?
  end

  class_methods do
    def aggregate_of(association)
      super

      revamp "rebuild_#{association}!" do |_, this, children, hyper|
        old_children = this.send association
        added_children = children - old_children
        hyper.(children)
        this.usages.each { |it| it.index_children!(added_children) }

        this
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
