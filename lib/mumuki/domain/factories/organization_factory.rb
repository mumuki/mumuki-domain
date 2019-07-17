FactoryBot.define do

  factory :organization do
    contact_email { Faker::Internet.email }
    description { 'a great org' }
    locale { 'en' }
    settings {}
    name { 'an-organization' }
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
    book
    skip_unique_name_validation
  end

  trait :skip_unique_name_validation do
    to_create { |instance| instance.save(validate: false) }
  end
end
