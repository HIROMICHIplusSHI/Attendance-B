Rails.application.routes.draw do
  concern :bulk_updatable do
    collection { patch :bulk_update }
  end

  get 'users/new'
  get 'static_pages/top'
  root 'static_pages#top'
  get '/signup', to: 'users#new'
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  resources :monthly_approvals, only: [:index], concerns: :bulk_updatable
  resources :attendance_change_approvals, only: [:index], concerns: :bulk_updatable

  resources :users do
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
    end
    resources :attendances, only: [:update] do
      collection do
        get 'edit_one_month'
        patch 'update_one_month'
      end
      resources :application_requests, only: %i[new create]
    end
    resources :monthly_approvals, only: [:create]
  end

  # ヘルスチェック用
  get "up" => "rails/health#show", as: :rails_health_check
end
