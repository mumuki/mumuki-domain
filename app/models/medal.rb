class Medal < ApplicationRecord
  has_many :users, as: :avatar
end
