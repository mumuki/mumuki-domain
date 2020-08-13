class AddIncognitoModeEnabledToOrganization < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :incognito_mode_enabled, :boolean
  end
end
