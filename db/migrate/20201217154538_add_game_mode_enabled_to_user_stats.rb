class AddGameModeEnabledToUserStats < ActiveRecord::Migration[5.1]
  def change
    add_column :user_stats, :game_mode_enabled, :boolean
  end
end
