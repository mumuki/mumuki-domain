class RenameCertificateDates < ActiveRecord::Migration[5.1]
  def change
    rename_column :certificates, :start_date, :started_at
    rename_column :certificates, :end_date, :ended_at
  end
end
