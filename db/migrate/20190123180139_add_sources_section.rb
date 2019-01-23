class AddSourcesSection < ActiveRecord::Migration[5.1]
  def change
    add_column :guides, :sources, :text
  end
end
