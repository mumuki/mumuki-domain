class AddMultifileToLanguages < ActiveRecord::Migration[5.1]
  def change
    add_column :languages, :multifile, :boolean, default: false
  end
end
