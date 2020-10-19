class AddMissplacedFlagToSubmission < ActiveRecord::Migration[5.1]
  def change
    add_column :assignments, :missplaced, :boolean
  end
end
