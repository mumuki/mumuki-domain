class AddSettingsToContent < ActiveRecord::Migration[5.1]
  def change
    add_column :exercises, :settings, :text
    add_column :guides, :settings, :text
  end
end
