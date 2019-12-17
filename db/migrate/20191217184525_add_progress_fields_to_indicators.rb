class AddProgressFieldsToIndicators < ActiveRecord::Migration[5.1]
  def change
    add_column :indicators, :children_passed_count, :integer
    add_column :indicators, :children_count, :integer
  end
end
