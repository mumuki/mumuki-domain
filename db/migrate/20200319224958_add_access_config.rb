class AddAccessConfig < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :access_config, :text
    add_column :courses, :access_config, :text
  end
end
