class UserService
  def self.signup(user_params)
    user = User.new(user_params)
    if user.save
      { success: true, message: "User created successfully", user: user }
    else
      { success: false, error: user.errors.full_messages }
    end
  end

  def self.login(login_params)
    user = User.find_by(email: login_params[:email])
    if user
      if user.authenticate(login_params[:password])
        token = JsonWebToken.encode({ name: user.name, email: user.email })
        { success: true, message: "Login successful", token: token }
      else
        { success: false, error: "Wrong password" }
      end
    else
      { success: false, error: "Email is not registered" }
    end
  end

  def self.forgetPassword(forget_params)
    user = User.find_by(email: forget_params[:email])
    if user
      @@otp = rand(100000..999999)
      @@otp_generated_at = Time.current
      begin
        UserMailer.enqueue_otp_email(user, @@otp)
        { success: true, message: "OTP has been sent to #{user.email}, check your inbox", otp: @@otp, otp_generated_at: @@otp_generated_at, user_id: user.id }
      rescue StandardError => e
        Rails.logger.error "Failed to enqueue OTP: #{e.message}"
        { success: false, error: "Failed to send OTP, please try again" }
      end
    else
        { success: false, error: "Email is not registered" }
    end
  end

  def self.resetPassword(user_id, reset_params)
    user = User.find_by(id: user_id)
    if !user
      return { success: false, error: "User not found" }
    end

    if reset_params[:otp].to_i != @@otp || (Time.current - @@otp_generated_at > 2.minute)
      return { success: false, error: "Invalid or expired OTP" }
    end

    if user.update(password: reset_params[:new_password])
      @@otp = nil
      @@otp_generated_at = nil
      UserMailer.password_reset_success_email(user).deliver_later
      { success: true, message: "Password successfully reset" }
    else
      { success: false, error: user.errors.full_messages }
    end
  end

  private
  @@otp = nil
  @@otp_generated_at = nil
end
