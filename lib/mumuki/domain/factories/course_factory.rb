FactoryBot.define do
  factory :course do
    period { '2016' }
    shifts { %w(morning) }
    code { "k1234-#{SecureRandom.uuid}" }
    days { %w(monday wednesday) }
    description { 'test' }
    organization_id { 1 }
    slug { "#{Organization.current.name}/#{period}-#{code}" }
  end
end
