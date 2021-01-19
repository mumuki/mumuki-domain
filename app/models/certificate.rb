class Certificate < ApplicationRecord
  belongs_to :user
  belongs_to :certification

  has_one :organization, through: :certification

end
