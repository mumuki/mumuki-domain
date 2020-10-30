class AddOnceCompletedToIndicators < ActiveRecord::Migration[5.1]
  def change
    add_column :indicators, :once_completed, :boolean
  end
end
