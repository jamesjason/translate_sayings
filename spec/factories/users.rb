FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    role { User::USER_ROLE }

    trait :google do
      provider { 'google_oauth2' }
      sequence(:uid) { |n| "google-uid-#{n}" }
    end

    trait :admin do
      role { User::ADMIN_ROLE }
    end
  end
end
