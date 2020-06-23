class UserStats < ApplicationRecord
  belongs_to :organization
  belongs_to :user

end
