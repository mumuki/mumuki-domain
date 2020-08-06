FactoryBot.define do

  factory :message do
    content { Faker::Lorem.sentence(3) }
  end
end
