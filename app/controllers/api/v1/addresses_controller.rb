module Api
  module V1
    class AddressesController < ApplicationController
      before_action :authenticate_request

      def index
        result = AddressService.list_addresses(current_user)
        user_data = {
          name: current_user.name,
          number: current_user.mobile_number  # Or phone, depending on your DB column
        }
        render json: { user: user_data, addresses: result[:addresses] }, status: :ok
      end

      def create
        result = AddressService.add_address(current_user, address_params)
        if result[:success]
          render json: { message: result[:message], address: result[:address] }, status: :created
        else
          render json: { message: result[:error] }, status: :unprocessable_entity
        end
      end

      def update
        result = AddressService.update_address(current_user, params[:id], address_params)
        if result[:success]
          render json: { message: result[:message], address: result[:address] }, status: :ok
        else
          render json: { message: result[:error] }, status: :unprocessable_entity
        end
      end

      def destroy
        result = AddressService.remove_address(current_user, params[:id])
        # Always return 200 OK, let the success flag dictate the outcome
        render json: result, status: :ok
      end

      private

      def address_params
        params.require(:address).permit(:street, :city, :state, :zip_code, :country, :type, :is_default)
      end

      def authenticate_user_from_token!
        token = request.headers["Authorization"]&.split(" ")&.last
        Rails.logger.info "Token received: #{token.inspect}"

        unless token
          Rails.logger.info "No token provided"
          render json: { message: "Unauthorized - No token provided" }, status: :unauthorized
          return
        end

        email = JsonWebToken.decode(token)
        Rails.logger.info "Decoded email: #{email.inspect}"

        if email
          @current_user = User.find_by(email: email)
          Rails.logger.info "User found: #{@current_user.inspect}"
          unless @current_user
            Rails.logger.info "User not found for email: #{email}"
            render json: { message: "Unauthorized - User not found" }, status: :unauthorized
            return
          end
        else
          Rails.logger.info "Token decode failed"
          render json: { message: "Unauthorized - Invalid token" }, status: :unauthorized
          return
        end
      end
      
      def current_user
        @current_user
      end
    end
  end
end