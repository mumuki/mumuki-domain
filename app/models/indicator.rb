class Indicator < Progress
  belongs_to :user
  belongs_to :content, polymorphic: true
  belongs_to :organization

  has_many :indicators, foreign_key: :parent_id, class_name: 'Indicator'
  has_many :assignments, foreign_key: :parent_id

  def propagate_up!(&block)
    instance_eval &block
    parent&.instance_eval { propagate_up! &block }
  end

  def self.dirty_by_content_change!(content)
    where(content: content).update_all dirty_by_content_change: true
  end

  def dirty_by_submission!
    propagate_up! { update! dirty_by_submission: true }
  end

  def rebuild!
    if dirty_by_content_change?
      propagate_up! do
        refresh_children_count!
        refresh_children_passed_count!
        clean!
        save!
      end
    elsif dirty_by_submission?
      refresh_children_passed_count!
      clean!
      save!
    end
  end

  def clean!
    self.dirty_by_submission = false
    self.dirty_by_content_change = false
  end

  def refresh_children_count!
    self.children_count = content.structural_children.count
  end

  def refresh_children_passed_count!
    self.children_passed_count = children.count(&:completed?)
  end

  def completion_ratio
    rebuild!
    children_passed_count.fdiv children_count
  end

  def completed?
    rebuild!
    children_passed_count == children_count
  end

  private

  def children
    indicators.presence || assignments
  end

  %i(children_count children_passed_count).each do |selector|
    define_method selector do
      send "refresh_#{selector}!" unless self[selector]

      self[selector]
    end
  end

  def parent_content
    usage = content.usage_in_organization(organization)
    raise "content #{content.name} is not in use in #{organization}" unless usage
    usage.structural_parent
  end
end
