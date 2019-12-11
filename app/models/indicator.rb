class Indicator < ApplicationRecord
  belongs_to :user
  belongs_to :content, polymorphic: true
  belongs_to :organization

  has_many :children, foreign_key: :parent_id, class_name: 'Indicator'
  has_many :assignments, foreign_key: :parent_id

  include Progress

  def self.dirty_for_content!(content)
    where(content: content).update_all dirty: true
  end

  private

  def parent_content
    content.usage_in_organization(organization).structural_parent
  end
end
