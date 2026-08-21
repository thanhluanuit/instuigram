require "sidekiq/web"

Rails.application.routes.draw do
  root to: "home#index"

  devise_for :users

  mount Sidekiq::Web => "/sidekiq"

  resources :users, only: [ :show, :edit, :update ]
  resources :posts, only: [ :create, :show, :destroy ] do
    resources :comments, only: [ :create ]
    resource :reaction, only: [ :create, :destroy ]
  end
  resources :comments, only: [ :destroy ]
  get "search" => "search#index"

  namespace :api do
    namespace :v1 do
      resources :clients, only: [ :create ]
      resource  :oauth,   only: [ :create ], controller: "oauth"
      resources :posts,   only: [ :index, :show, :create, :destroy ]
    end
  end
end
