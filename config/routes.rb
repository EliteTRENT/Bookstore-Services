Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/swagger"
  namespace :api do
    namespace :v1 do
      post "users" => "users#create"
      post "sessions" => "users#login"
      post "sessions/refresh" => "users#refresh"
      post "users/password/forgot" => "users#forgot_password"
      post "users/password/reset/:id" => "users#reset_password"

      post "wishlists" => "wishlists#create"
      get "wishlists" => "wishlists#index"
      patch "wishlists/:wishlist_id" => "wishlists#mark_book_as_deleted"
      patch "wishlists/:book_id" => "wishlists#mark_book_as_deleted"

      post "books" => "books#create"
      get "books/search_suggestions" => "books#search_suggestions"
      get "books/stock" => "books#stock"
      patch "books/:id" => "books#update"
      get "books" => "books#index"
      get "books/:id" => "books#show"
      patch "books/delete/:id" => "books#toggle_delete"
      delete "books/:id" => "books#destroy"

      post "reviews" => "reviews#create"
      get "reviews/:book_id" => "reviews#show"
      delete "reviews/:id" => "reviews#destroy"

      post "addresses" => "addresses#create"
      get "addresses" => "addresses#index"
      patch "addresses/:id" => "addresses#update"
      delete "addresses/:id" => "addresses#destroy"

      post "orders" => "orders#create"
      get "orders" => "orders#index"
      get "orders/:id" => "orders#show"
      patch "orders/:id" => "orders#update_status"

      post "carts" => "carts#create"
      get "carts/:user_id" => "carts#get_cart"
      delete "carts/:book_id" => "carts#soft_delete_book"
      patch "carts" => "carts#update_quantity"

      post "google_auth" => "google_auth#create"
    end
  end
end
