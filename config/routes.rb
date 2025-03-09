Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/swagger"
  namespace :api do
    namespace :v1 do
      post "users/signup" => "users#signup"
      post "users/login" => "users#login"
      post "users/forget" => "users#forgetPassword"
      post "users/reset/:id" => "users#resetPassword"

      post "books/create" => "books#create"
      patch "books/update/:id" => "books#update"
      get "books" => "books#index"
      get "books/show/:id" => "books#show"
    end
  end
end
