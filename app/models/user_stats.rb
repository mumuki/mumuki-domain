class UserStats < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  def add_exp!(points)
    self.exp += points
  end
end
