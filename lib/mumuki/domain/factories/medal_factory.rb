FactoryBot.define do
  factory :medal do
    image_url { Faker::Internet.url }
  end
end

