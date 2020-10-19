class AddMisplacedFlagToSubmission < ActiveRecord::Migration[5.1]
  def change
    add_column :assignments, :misplaced, :boolean
  end
end
