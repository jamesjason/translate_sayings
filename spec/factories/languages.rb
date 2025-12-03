FactoryBot.define do
  factory :language do
    code { 'en' }
    name { 'English' }

    trait :fa do
      code { 'fa' }
      name { 'Persian' }
    end

    trait :es do
      code { 'es' }
      name { 'Spanish' }
    end

    initialize_with do
      Language.find_or_create_by(code:) do |lang|
        lang.name = name
      end
    end
  end
end
