class AddDatesToCertificateProgram < ActiveRecord::Migration[5.1]
  def change
    add_column :certificate_programs, :start_date, :datetime
    add_column :certificate_programs, :end_date, :datetime
  end
end
