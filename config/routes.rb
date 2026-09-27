Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  get "search" => "products#index", as: :search
  get "search/suggestions" => "products#suggestions", as: :search_suggestions

  resources :categories, only: [ :show ], param: :slug
  resources :products, only: [ :index, :show ], param: :slug do
    resources :product_reviews, only: [ :create, :destroy ], shallow: true
  end

  resource :cart, only: [ :show ] do
    post :add_item
    patch "items/:item_id", action: :update_item, as: :update_item
    delete "items/:item_id", action: :remove_item, as: :remove_item
  end

  resource :wishlist, only: [ :show ] do
    post :toggle
  end

  resources :quotes, only: [ :index, :new, :create, :show ] do
    member do
      post :accept
      post :reject
    end
  end

  resources :addresses, except: [ :show ]

  resources :orders, only: [ :index, :new, :create, :show ] do
    member do
      post :cancel
    end
  end

  resource :profile, only: [ :show, :edit, :update ]

  namespace :admin do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"

    resources :categories
    resources :products
    resources :orders, only: [ :index, :show, :update ]
    resources :quotes, only: [ :index, :show, :update ] do
      member { post :send_quote }
    end
    resources :coupons
    resources :users, only: [ :index, :show, :update ]
  end
end
