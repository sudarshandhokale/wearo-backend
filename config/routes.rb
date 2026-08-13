Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/confirmations", to: "auth#resend_confirmation"
      post "auth/confirmations/verify", to: "auth#confirm_email"
      post "auth/password/forgot", to: "auth#forgot_password"
      post "auth/password/reset", to: "auth#reset_password"
      post "auth/refresh", to: "auth#refresh"
      post "auth/logout", to: "auth#logout"
      delete "auth/logout", to: "auth#logout"

      get "health", to: "health#show"
      get "health/readiness", to: "health#readiness"
      get "metadata", to: "metadata#index"
      get "media/:id", to: "media#show", as: :medium
      get "ai/usage", to: "ai_usage#show"
      get "context", to: "external_contexts#show"
      post "stylist/recommendations", to: "stylist#recommendations"
      resource :me, only: %i[show update destroy], controller: :me
      delete "me/full_body_image", to: "me#destroy_full_body_image"
      patch "me/consents", to: "me#update_consents"
      get "me/export", to: "me#export"
      resource :style_profile, only: %i[show update], controller: :style_profiles
      resource :wardrobe, only: :show, controller: :wardrobes
      resources :clothing_items do
        post :reanalyze, on: :member
        post :polish, on: :member
      end
      resources :recommendation_requests, only: %i[index show]
      resources :outfits, only: %i[index show update] do
        post :wear, on: :member
        post :feedback, on: :member
        resources :visualizations, only: %i[index show create], controller: :outfit_visualizations
      end
      resources :wear_history, only: :index, controller: :wear_histories
      resources :styling_plans, only: %i[index show create]
      resources :styling_routines do
        post :drafts, on: :collection
      end
      resources :routine_occurrences, only: :index do
        get :today, on: :collection
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
