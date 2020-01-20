class CreateIndicators < ActiveRecord::Migration[5.1]
  def change
    create_table :indicators do |t|
      t.references :user
      t.references :organization
      t.references :parent
      t.references :content, polymorphic: true

      t.timestamps
    end
  end
end
