class AddExpectationsToLanguage < ActiveRecord::Migration[5.1]
  def change
    add_column :languages, :expectations, :boolean
  end
end
