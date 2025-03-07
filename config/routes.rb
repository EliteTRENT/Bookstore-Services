Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/swagger"
  namespace :api do
    namespace :v1 do
      post "users/signup" => "users#signup"
      post "users/login" => "users#login"
      post "users/forget" => "users#forgetPassword"
      post "users/reset/:id" => "users#resetPassword"
    end
  end
end
