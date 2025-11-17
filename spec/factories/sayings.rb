FactoryBot.define do
  factory :saying do
    association :language
    text { "actions speak louder than words" }
  end
end
