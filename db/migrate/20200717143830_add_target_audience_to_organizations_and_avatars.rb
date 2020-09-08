class AddTargetAudienceToOrganizationsAndAvatars < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :target_audience, :integer, default: 0
    add_column :avatars, :target_audience, :integer, default: 0
  end
end
