FactoryBot.define do
  factory :avatar do
    image_url { Faker::Internet.url }
    target_visual_identity { :grown_ups }
  end
end
