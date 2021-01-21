class AddPreventManualEvaluationContentToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :prevent_manual_evaluation_content, :boolean
  end
end
