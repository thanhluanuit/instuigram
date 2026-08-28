require "sidekiq/web"

Rails.application.routes.draw do
  root to: "home#index"

  devise_for :users

  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  resources :users, only: [ :show, :edit, :update ]
  resources :posts, only: [ :create, :show, :destroy ] do
    resources :comments, only: [ :create ]
    resource :reaction, only: [ :create, :destroy ]
  end
  resources :comments, only: [ :destroy ]
  get "search" => "search#index"

  resources :conversations, only: [ :index, :show, :new, :create ] do
    resources :messages, only: [ :create ]
    resource  :read,     only: [ :create ], module: :conversations
  end

  namespace :api do
    namespace :v1 do
      resources :clients, only: [ :create ]
      resource  :oauth,   only: [ :create ], controller: "oauth"
      resources :posts,   only: [ :index, :show, :create, :destroy ]
    end
  end
end
