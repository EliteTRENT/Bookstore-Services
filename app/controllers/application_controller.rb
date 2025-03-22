class ApplicationController < ActionController::API
  before_action :authenticate_request

  private

  def authenticate_request
    token = request.headers["Authorization"]&.split(" ")&.last
    unless token
      render json: { error: "Missing token" }, status: :unauthorized
      return
    end
    begin
      decoded = JsonWebToken.decode(token)
      @current_user = User.find_by(id: decoded["id"]) # Use id from token
      unless @current_user
        render json: { error: "Session expired" }, status: :unauthorized
        return
      end
      # Optional: Match user_id from request if present (e.g., for /carts/:user_id)
      user_id_from_request = params[:user_id] || request.path_parameters[:user_id]
      if user_id_from_request && user_id_from_request.to_i != @current_user.id
        render json: { error: "Session expired" }, status: :unauthorized
      end
    rescue JWT::DecodeError => e
      render json: { error: "Session expired" }, status: :unauthorized
    end
  end
end