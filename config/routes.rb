Rails.application.routes.draw do
  root to: "home#index"

  devise_for :users
  resources :users, only: [ :show, :edit, :update ]
  resources :posts, only: [ :create, :show, :destroy ] do
    resource :reaction, only: [ :create, :destroy ]
  end
  get "search" => "search#index"
end
