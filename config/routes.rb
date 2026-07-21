Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # ねこの相談室（質問一覧・投稿フォーム・投稿）と回答
  resources :questions, only: %i[index new create show] do
    resources :answers, only: %i[new create]
  end

  # Defines the root path route ("/")
  # 未ログイン時は home#index の authenticate_user! で /users/sign_in へ誘導される。
  root "home#index"
end
