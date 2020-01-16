FactoryBot.define do

  factory :guide do
    sequence(:name) { |n| "guide#{n}" }
    locale { 'en' }
    description { 'A Guide' }
    slug { "flbulgarelli/mumuki-sample-guide-#{SecureRandom.uuid}" }
    language
  end

  trait :guide_container do
    transient do
      exercises { [] }
      name { Faker::Lorem.sentence(3) }
      description { Faker::Lorem.sentence(10) }
      language { create(:language) }
      slug { "mumuki/mumuki-test-lesson-#{SecureRandom.uuid}" }
    end

    after(:build) do |lesson, evaluator|
      lesson.guide = build(:guide,
                           name: evaluator.name,
                           slug: evaluator.slug,
                           exercises: evaluator.exercises,
                           description: evaluator.description,
                           language: evaluator.language) unless evaluator.guide
    end
  end

  factory :indexed_guide, parent: :guide do
    after(:build) do |guide|
      create(:lesson, guide: guide, topic: create(:indexed_topic))

      reindex_current_organization!
    end
  end
end
