Rails.application.routes.draw do
  get 'users/new'
  get 'static_pages/top'
  root 'static_pages#top'
  get '/signup', to: 'users#new'
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  resources :users do
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month'
    end
    resources :attendances, only: [:update] do
      collection do
        get 'edit_one_month'
        patch 'update_one_month'
      end
    end
  end

  # ヘルスチェック用
  get "up" => "rails/health#show", as: :rails_health_check
end
