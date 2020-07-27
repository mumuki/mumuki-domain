FactoryBot.define do
  factory :avatar do
    image_url { Faker::Internet.url }
    target_audience { :grown_ups }
  end
end
