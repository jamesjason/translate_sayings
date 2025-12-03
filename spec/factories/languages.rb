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
      Language.find_or_initialize_by(code: code).tap do |lang|
        lang.name = name
        lang.save! if lang.changed?
      end
    end
  end
end
