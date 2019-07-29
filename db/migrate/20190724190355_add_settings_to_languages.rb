class AddSettingsToLanguages < ActiveRecord::Migration[5.1]
  def change
    add_column :languages, :settings, :boolean, default: false
  end
end
