class AddImmersibleToOrganization < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :immersible, :boolean, default: false
  end
end
