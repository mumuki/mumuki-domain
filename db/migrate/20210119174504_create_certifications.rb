class CreateCertifications < ActiveRecord::Migration[5.1]
  def change
    create_table :certifications do |t|
      t.string :title
      t.string :template_html_erb
      t.text :description
      t.references :organization, foreign_key: true

      t.timestamps
    end
  end
end
