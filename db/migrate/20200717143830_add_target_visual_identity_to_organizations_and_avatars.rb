class AddTargetVisualIdentityToOrganizationsAndAvatars < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :target_visual_identity, :integer, default: 0
    add_column :avatars, :target_visual_identity, :integer, default: 0
  end
end
