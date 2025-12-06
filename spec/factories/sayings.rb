FactoryBot.define do
  factory :saying do
    association :language
    sequence(:text) { |n| "actions speak louder than words #{n}" }
    sequence(:slug) { |n| "actions-speak-louder-than-words-#{n}" }
  end
end
