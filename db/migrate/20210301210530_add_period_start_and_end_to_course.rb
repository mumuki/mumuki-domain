class AddPeriodStartAndEndToCourse < ActiveRecord::Migration[5.1]
  def change
    add_column :courses, :period_start, :datetime
    add_column :courses, :period_end, :datetime
  end

end
