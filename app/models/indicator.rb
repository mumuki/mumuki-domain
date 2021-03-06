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
    self.once_completed ||= all_children_passed?
  end

  def refresh_children_count!
    self.children_count = content.structural_children.count
  end

  def refresh_children_passed_count!
    self.children_passed_count = children.count(&:completed?)
  end

  def completion_percentage
    rebuild!
    children_passed_count.fdiv children_count
  end

  def completed?
    rebuild!
    all_children_passed?
  end

  def once_completed?
    self.once_completed || completed?
  end

  def self.delete_all_for!(content, organization)
    where(content: content, organization: organization).delete_all
  end

  def _move_to!(organization)
    move_children_to!(organization)
    super
  end

  def _copy_to!(organization)
    progress_item = super
    children.each { |it| it._copy_to! organization }
    progress_item
  end

  def move_children_to!(organization)
    children.update_all(organization_id: organization.id)

    indicators.each { |it| it.move_children_to!(organization) }
  end

  def cascade_delete_children!
    indicators.each(&:cascade_delete_children!)
    children.delete_all(:delete_all)
  end

  def content_available_in?(organization)
    content.usage_in_organization(organization).present?
  end

  def delete_duplicates_in!(organization)
    duplicates_in(organization).each(&:cascade_delete_children!)
    super
  end

  private

  def duplicates_key
    { content: content, user: user }
  end

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
    content.usage_in_organization(organization).structural_parent
  end

  def all_children_passed?
    children_passed_count == children_count
  end
end
