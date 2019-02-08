FactoryBot.define do

  factory :chapter do
    number { Faker::Number.between(1, 40) }
    book { Organization.current.book rescue nil }

    transient do
      lessons { [] }
      name { Faker::Lorem.sentence(3) }
      slug { "mumuki/mumuki-test-topic-#{SecureRandom.uuid}" }
    end

    after(:build) do |chapter, evaluator|
      chapter.topic = build(:topic, name: evaluator.name, slug: evaluator.slug, lessons: evaluator.lessons) unless evaluator.topic
    end
  end
end
