class AddLoadingFlagsToLanguage < ActiveRecord::Migration[5.1]
  def change
    add_column :languages, :layout_shows_loading_content, :boolean
    add_column :languages, :editor_shows_loading_content, :boolean
  end
end
