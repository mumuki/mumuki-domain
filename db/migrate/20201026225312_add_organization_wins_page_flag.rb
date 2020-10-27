class AddOrganizationWinsPageFlag < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :wins_page, :boolean
  end
end
