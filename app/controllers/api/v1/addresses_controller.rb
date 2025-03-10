module Api
  module V1
    class AddressesController < ApplicationController
      before_action :authenticate_user! # Assuming JWT or Devise from UsersController
      skip_before_action :verify_authenticity_token # Matches UsersController

      def index
        result = AddressService.list_addresses(current_user)
        render json: { addresses: result[:addresses] }, status: :ok
      end

      def create
        result = AddressService.add_address(current_user, address_params)
        if result[:success]
          render json: { message: result[:message], address: result[:address] }, status: :created
        else
          render json: { errors: result[:error] }, status: :unprocessable_entity
        end
      end

      def update
        result = AddressService.update_address(current_user, params[:id], address_params)
        if result[:success]
          render json: { message: result[:message], address: result[:address] }, status: :ok
        else
          render json: { errors: result[:error] }, status: :unprocessable_entity
        end
      end

      def destroy
        result = AddressService.remove_address(current_user, params[:id])
        if result[:success]
          render json: { message: result[:message] }, status: :ok
        else
          render json: { errors: result[:error] }, status: :unprocessable_entity
        end
      end

      private

      def address_params
        params.require(:address).permit(:street, :city, :state, :zip_code, :country, :type, :is_default)
      end
    end
  end
end