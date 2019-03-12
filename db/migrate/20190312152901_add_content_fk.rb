class AddContentFk < ActiveRecord::Migration[5.1]
  def change
    add_foreign_key :exams, :guides
    add_foreign_key :lessons, :guides
    add_foreign_key :complements, :guides
    add_foreign_key :chapters, :topics
    add_foreign_key :organizations, :books
  end
end
