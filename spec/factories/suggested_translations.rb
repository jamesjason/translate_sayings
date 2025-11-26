FactoryBot.define do
  factory :suggested_translation do
    association :user
    association :source_language, factory: :language
    association :target_language, factory: %i[language fa]

    source_saying_text { Faker::Lorem.sentence(word_count: rand(3..8)).downcase }
    target_saying_text { Faker::Lorem.sentence(word_count: rand(3..8)).downcase }

    status { 'pending_review' }
  end
end
