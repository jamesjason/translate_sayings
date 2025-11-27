FactoryBot.define do
  factory :saying_translation do
    association :saying_a, factory: :saying
    association :saying_b, factory: :saying
  end
end
