class AddDirtinessToIndicators < ActiveRecord::Migration[5.1]
  def change
    add_column :indicators, :dirty_by_content_change, :boolean, default: false
    add_column :indicators, :dirty_by_submission, :boolean, default: false
  end
end
