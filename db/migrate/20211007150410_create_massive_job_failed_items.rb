class CreateMassiveJobFailedItems < ActiveRecord::Migration[5.1]
  def change
    create_table :massive_job_failed_items do |t|
      t.references :massive_job, index: true
      t.string :uid
      t.text :stacktrace
      t.text :message

      t.timestamps
    end
  end
end
