FactoryBot.define do
  factory :map do
    sequence(:name) { |n| "4p_Map#{n}" }
    category { "competitive" }
    enabled { true }
  end
end
