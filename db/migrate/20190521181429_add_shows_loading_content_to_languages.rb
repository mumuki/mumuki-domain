class AddShowsLoadingContentToLanguages < ActiveRecord::Migration[5.1]
  def change
    add_column :languages, :layout_shows_loading_content, :boolean, default: false
    add_column :languages, :editor_shows_loading_content, :boolean, default: false
  end
end
