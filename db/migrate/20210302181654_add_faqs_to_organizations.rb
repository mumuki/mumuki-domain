class AddFaqsToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :faqs, :text
  end
end
