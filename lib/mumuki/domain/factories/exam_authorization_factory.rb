FactoryBot.define do
  factory :exam_authorization do
    exam { create(:exam) }
  end
end
