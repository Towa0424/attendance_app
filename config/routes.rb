Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]

  devise_scope :user do
    root to: "devise/sessions#new"
  end

  resources :time_records, only: [:index, :create]

  namespace :admin do
    resources :users, only: [:index, :new, :create, :edit, :update]
  end
end
