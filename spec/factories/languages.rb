FactoryBot.define do
  factory :language do
    code { 'en' }
    name { 'English' }

    trait :fa do
      code { 'fa' }
      name { 'Persian' }
    end
  end
end
