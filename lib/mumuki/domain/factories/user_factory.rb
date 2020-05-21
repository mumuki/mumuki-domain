FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    uid { email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    gender { 1 }
    birthdate { Date.today }
    avatar { Avatar.new image_url: 'user_shape.png' }
  end
end
