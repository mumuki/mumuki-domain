class AddDirtyToIndicators < ActiveRecord::Migration[5.1]
  def change
    add_column :indicators, :dirty, :boolean, default: false
  end
end
