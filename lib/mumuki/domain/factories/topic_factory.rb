FactoryBot.define do

  factory :topic do
    name { Faker::Lorem::sentence(3) }
    description { Faker::Lorem.paragraph(2) }
    slug { "mumuki/mumuki-sample-topic-#{SecureRandom.uuid}" }
    locale { :en }
  end

  factory :indexed_topic, parent: :topic do
    after(:build) do |topic|
      create(:chapter, topic: topic)
    end
  end
end
