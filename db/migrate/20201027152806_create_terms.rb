class CreateTerms < ActiveRecord::Migration[5.1]
  def change
    create_table :terms do |t|
      t.string :locale
      t.string :scope
      t.text :content
      t.text :header

      t.timestamps
    end
  end
end
