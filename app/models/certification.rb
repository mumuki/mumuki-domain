class Certification < ApplicationRecord
  belongs_to :organization

  def friendly
    title
  end

end
