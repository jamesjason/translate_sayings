FactoryBot.define do
  factory :translation_vote do
    association :user
    association :saying_translation
    vote { 0 }
  end
end
