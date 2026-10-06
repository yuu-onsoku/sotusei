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
  resources :questions, only: %i[index new create show edit update destroy] do
    resources :answers, only: %i[new create edit update destroy]
    # 肉球ボタン（いいね）。付ける／外すを別々の操作にして、
    # 同じ送信が二重に届いても結果が変わらないようにする。
    resource :like, only: %i[create destroy]
    # コメント（質問へ）
    resources :comments, only: %i[create edit update destroy]
  end

  # 回答へのいいね
  resources :answers, only: [] do
    resource :like, only: %i[create destroy]
    # コメント（回答へ）
    resources :comments, only: %i[create edit update destroy]
  end

  # にゃんスタ（うちの子自慢の写真投稿）
  resources :posts do
    resource :like, only: %i[create destroy]
    resource :bookmark, only: %i[create destroy]
    resources :comments, only: %i[create edit update destroy]
  end

  # 保存した投稿の一覧
  resources :bookmarks, only: :index

  # お迎え診断（未ログインでも使える入口機能）
  resources :diagnoses, only: %i[new create] do
    get :result, on: :collection
  end

  # 覚悟のチェックリスト（ログイン後の機能）
  resources :checklists, only: %i[new create] do
    get :result, on: :collection
  end
  # 静的ページ（未ログインでも見られる）
  get "terms", to: "pages#terms"
  get "privacy", to: "pages#privacy"

  # お問い合わせ（ログインできない人からの連絡も受け取るため、ログイン不要）
  resources :contacts, only: %i[new create]
  # マイページ（自分が書いたもの・保存したものをまとめて見る）
  get "mypage", to: "mypages#show"

  # Defines the root path route ("/")
  # 未ログイン時は home#index の authenticate_user! で /users/sign_in へ誘導される。
  root "home#index"
end
