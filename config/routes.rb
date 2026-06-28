Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  scope module: :api do
    namespace :v1 do
      namespace :user do
        post :check_status, to: "check_status#create"
      end
    end
  end
end
