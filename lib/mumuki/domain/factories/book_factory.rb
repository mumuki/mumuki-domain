FactoryBot.define do
  factory :book do
    name { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.sentence(word_count: 30) }
    slug { "mumuki/mumuki-test-book-#{SecureRandom.uuid}" }
  end

  factory :book_with_full_tree, parent: :book do
    transient do
      children_factor { 3 }
      exercises { create_list(:exercise, children_factor) }
      lessons { create_list(:lesson, children_factor, exercises: exercises) }
      chapters { create_list(:chapter, children_factor, lessons: lessons) }
    end

    after(:build) do |book, evaluator|
      book.chapters = evaluator.chapters
    end
  end
end
