FactoryBot.define do

  factory :organization do
    contact_email { Faker::Internet.email }
    description { 'a great org' }
    locale { 'en' }
    settings {}
    name { 'an-organization' }
    time_zone { 'UTC' }
    book
  end

  factory :private_organization, parent: :organization do
    name { 'the-private-org' }
  end

  factory :public_organization, parent: :organization do
    public { true }
    name { 'the-public-org' }
    login_methods { Mumukit::Login::Settings.login_methods }
  end

  factory :base, parent: :public_organization do
    name { 'base' }
  end

  factory :test_organization, parent: :public_organization do
    name { 'test' }
    immersible { true }
    book { create(:book, name: 'test', slug: 'mumuki/mumuki-the-book') }
  end

  factory :another_test_organization, parent: :test_organization do
    name { 'another-test' }
    book { create(:book, name: 'another-test', slug: 'mumuki/mumuki-another-book') }
  end

  trait :skip_unique_name_validation do
    to_create { |instance| instance.save(validate: false) }
  end
end
