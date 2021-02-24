class CreateCertificates < ActiveRecord::Migration[5.1]
  def change
    create_table :certificates do |t|
      t.references :user, index: true
      t.references :certificate_program, index: true
      t.datetime :start_date
      t.datetime :end_date
      t.string :code

      t.timestamps
    end
  end
end
