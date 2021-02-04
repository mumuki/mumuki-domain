class CreateCertificates < ActiveRecord::Migration[5.1]
  def change
    create_table :certificates do |t|
      t.references :user, foreign_key: true
      t.references :certification, foreign_key: true
      t.datetime :start_date
      t.datetime :end_date
      t.string :code

      t.timestamps
    end
  end
end
