Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]

  devise_scope :user do
    root to: "devise/sessions#new"
  end

  resources :time_records, only: [:index, :create]
  resources :shifts, only: [:index]

  resources :time_off_requests, only: [:index] do
    collection do
      post :toggle
    end
  end

  namespace :admin do
    resources :users, only: %i[index new create edit update]
    resources :groups, only: %i[index new create edit update]
    resources :time_blocks, only: %i[index new create edit update]
    resources :shift_patterns, only: %i[index new create edit update]

    resources :shifts, only: %i[index] do
      collection do
        patch :assign
        patch :update_details
      end
    end

    resources :time_off_locks, only: [] do
      collection do
        patch :toggle
      end
    end
  end
end
