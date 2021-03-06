FactoryBot.define do

  factory :language do
    sequence(:name) { |n| "lang#{n}" }

    runner_url { Faker::Internet.url }
    queriable { true }
  end

  factory :haskell, parent: :language do
    name { 'haskell' }
  end

  factory :bash, parent: :language do
    name { 'bash' }
    triable { true }
    stateful_console { true }
  end

  factory :text_language, parent: :language do
    name { 'text' }
  end

  factory :gobstones, parent: :language do
    name { 'gobstones' }
    extension { 'gbs' }
    queriable { false }
  end

  factory :exercise_base do
    transient do
      indexed { false }
    end

    language { guide ? guide.language : create(:language) }
    sequence(:bibliotheca_id) { |n| n }
    sequence(:number) { |n| n }

    locale { :en }
    guide

    after(:build) do |exercise, evaluator|
      exercise.guide = create(:indexed_guide) if evaluator.indexed
    end
  end

  factory :challenge, parent: :exercise_base do
    layout { 'input_right' }
  end

  factory :reading, class: Reading, parent: :exercise_base do
    name { 'A reading' }
    description { 'Simple reading' }
  end

  factory :problem, class: Problem, parent: :challenge do
    name { 'A problem' }
    description { 'Simple problem' }
    test { 'dont care' }
  end

  factory :multiple_choice, parent: :problem do
    name { 'A multiple choice problem' }
    editor { :multiple_choice }
    description { 'Simple multiple choice problem' }
    choices { [{value: 'a', checked: true}, {value: 'b', checked: false }] }
  end

  factory :interactive, class: Interactive, parent: :challenge do
    name { 'An interactive problem' }
    description { 'Simple interactive problem' }
    goal { :query_passes }
    language { create(:bash) }
  end

  factory :playground, class: Playground, parent: :challenge do
    name { 'A Playground' }
    description { 'Simple playground' }
  end

  factory :exercise, parent: :problem

  factory :indexed_exercise, parent: :exercise do
    indexed { true }
  end

  factory :x_equal_5_exercise, parent: :exercise do
    test { 'describe "x" $ do
             it "should be equal 5" $ do
                x `shouldBe` 5' }
  end
end
