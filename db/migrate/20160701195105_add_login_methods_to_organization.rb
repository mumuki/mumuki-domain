class AddLoginMethodsToOrganization < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :login_methods, :string, array: true, default: [], null: false
  end
end
