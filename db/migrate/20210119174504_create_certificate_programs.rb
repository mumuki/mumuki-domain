class CreateCertificatePrograms < ActiveRecord::Migration[5.1]
  def change
    create_table :certificate_programs do |t|
      t.string :title
      t.string :template_html_erb
      t.text :description
      t.string :background_image_url
      t.references :organization, index: true

      t.timestamps
    end
  end
end
