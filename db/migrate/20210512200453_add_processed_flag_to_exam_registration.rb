class AddProcessedFlagToExamRegistration < ActiveRecord::Migration[5.1]
  def change
    add_column :exam_registrations, :processed, :boolean, default: false
  end
end
