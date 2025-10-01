Rails.application.routes.draw do
  # API routes
  devise_for :users,
    path: "v1/auth",
    path_names: {
      sign_in: "login",
      sign_out: "logout",
      registration: "signup"
    },
    controllers: {
      sessions: "v1/auth/sessions",
      registrations: "v1/auth/registrations",
      passwords: "v1/auth/passwords"
    },
    skip: [:omniauth_callbacks]

  # V1 API endpoints
  namespace :v1 do
    resources :levels, only: [:index]
    resources :user_levels, only: [:index]

    # Always have the param as lesson slug - auto-prefixed in the second
    resources :lessons, only: [:show], param: :lesson_slug
    resources :lessons, only: [], param: :slug do
      resources :exercise_submissions, only: [:create]
    end

    resources :user_lessons, only: [], param: :lesson_slug do
      member do
        post :start
        patch :complete
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
