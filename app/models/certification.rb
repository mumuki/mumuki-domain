class Certification < ApplicationRecord
  belongs_to :organization
  has_many :certificates

  def friendly
    title
  end

end
