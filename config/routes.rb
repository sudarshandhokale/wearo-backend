Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/refresh", to: "auth#refresh"
      post "auth/logout", to: "auth#logout"
      delete "auth/logout", to: "auth#logout"

      get "health", to: "health#show"
      get "metadata", to: "metadata#index"
      post "stylist/recommendations", to: "stylist#recommendations"
      resource :me, only: %i[show update], controller: :me
      resource :style_profile, only: %i[show update], controller: :style_profiles
      resource :wardrobe, only: :show, controller: :wardrobes
      resources :clothing_items do
        post :reanalyze, on: :member
      end
      resources :outfits, only: :show
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
