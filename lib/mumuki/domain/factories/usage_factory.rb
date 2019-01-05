FactoryBot.define do
  factory :usage do
    item { create(:topic) }
    parent_item { create(:chapter) }
  end
end
