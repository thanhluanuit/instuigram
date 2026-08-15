Rails.application.routes.draw do
  root to: "home#index"

  devise_for :users
  resources :users, only: [ :show, :edit, :update ]
  resources :posts, only: [ :create, :show, :destroy ] do
    resources :comments, only: [ :create ]
    resource :reaction, only: [ :create, :destroy ]
  end
  resources :comments, only: [ :destroy ]
  get "search" => "search#index"
end
