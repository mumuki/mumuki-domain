class CreateMassiveJobs < ActiveRecord::Migration[5.1]
  def change
    create_table :massive_jobs do |t|
      t.references :user
      t.references :target, polymorphic: true
      t.integer :total_count
      t.integer :failed_count, default: 0
      t.integer :processed_count, default: 0

      t.timestamps
    end
  end
end
