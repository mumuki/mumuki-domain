class Indicator < ApplicationRecord
  belongs_to :user
  belongs_to :content, polymorphic: true
  belongs_to :organization

  has_many :children, as: :parent

  include Progress

  def parent_content
    content.usage_in_organization(organization).structural_parent
  end
end
