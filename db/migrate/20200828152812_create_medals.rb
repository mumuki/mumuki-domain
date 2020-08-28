class CreateMedals < ActiveRecord::Migration[5.1]
  def change
    create_table :medals do |t|
      t.string :image_url
      t.string :description
    end
  end
end
