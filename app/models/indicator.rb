class Indicator < ApplicationRecord
  belongs_to :user
  belongs_to :content, polymorphic: true
  belongs_to :organization

  has_many :indicators, foreign_key: :parent_id, class_name: 'Indicator'
  has_many :assignments, foreign_key: :parent_id

  include Progress

  def self.dirty_for_content!(content)
    where(content: content).update_all dirty: true
  end

  def dirty!
    update! dirty: true
    dirty_parent!
  end

  def completion_percentage
    children_passed_count.fdiv children_count
  end

  def completed?
    children_passed_count == children_count
  end

  private

  def children
    indicators.presence || assignments
  end

  def children_count
    unless self[:children_count]
      update!(children_count: content.children.count)
    end

    self[:children_count]
  end

  def update_passed_children!
    update!(children_passed_count: children.count(&:completed?))
  end

  def children_passed_count
    if dirty? || !self[:children_passed_count]
      update_passed_children!
    end

    self[:children_passed_count]
  end

  def parent_content
    content.usage_in_organization(organization).structural_parent
  end
end
