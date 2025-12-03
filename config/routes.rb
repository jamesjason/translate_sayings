Rails.application.routes.draw do
  devise_for :users,
             controllers: {
               omniauth_callbacks: 'users/omniauth_callbacks'
             },
             skip: [:registrations]

  # Re-enable only the Devise signup routes
  as :user do
    get  'users/sign_up', to: 'devise/registrations#new',    as: :new_user_registration
    post 'users',         to: 'devise/registrations#create', as: :user_registration
  end

  get 'up' => 'rails/health#show', as: :rails_health_check

  root 'translations#index'

  get '/contribute', to: 'suggested_translations#new', as: :contribute

  resources :suggested_translations, only: %i[new create]

  resources :translations, only: [:index]

  resources :sayings, only: [] do
    collection do
      get :autocomplete
    end
  end

  resources :translation_reviews, only: [:index] do
    post :vote, on: :collection
  end
end
