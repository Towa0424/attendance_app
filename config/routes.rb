Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]

  devise_scope :user do
    root to: "devise/sessions#new"
  end

  resources :time_records, only: [:index, :create]

  namespace :admin do
    resources :users, only: %i[index new create edit update]
    resources :groups, only: %i[index new create edit update]
    resources :time_blocks, only: %i[index new create edit update]
  end
end
