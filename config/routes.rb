Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/swagger"
  namespace :api do
    namespace :v1 do
      post "users/signup" => "users#signup"
      post "users/login" => "users#login"
      post "users/forget" => "users#forgetPassword"
      post "users/reset/:id" => "users#resetPassword"


      post "wishlists/add" => "wishlists#addBook"
      get "wishlists/getAll" => "wishlists#getAll"
      delete "wishlists/destroy/:book_id" => "wishlists#destroy"

      post "books/create" => "books#create"
      patch "books/update/:id" => "books#update"
      get "books" => "books#index"
      get "books/show/:id" => "books#show"
      patch "books/toggle_delete/:id" => "books#toggle_delete"
      delete "books/:id" => "books#destroy"

      post "reviews/add" => "reviews#add_review"
      get "reviews/:book_id" => "reviews#get_reviews"
      delete "reviews/:id" => "reviews#delete_review"

      # New Address routes
      post "addresses/add" => "addresses#create"
      get "addresses/list" => "addresses#index"
      patch "addresses/update/:id" => "addresses#update"
      delete "addresses/remove/:id" => "addresses#destroy"

      post "orders/create" => "orders#create"
      get "orders" => "orders#index"
    end
  end
end
