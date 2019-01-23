class AddLearnMoreSection < ActiveRecord::Migration[5.1]
  def change
    add_column :guides, :learn_more, :text
  end
end
