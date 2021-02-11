class AddBackgroundUrlToCertification < ActiveRecord::Migration[5.1]
  def change
    add_column :certifications, :background_image_url, :string
  end
end
