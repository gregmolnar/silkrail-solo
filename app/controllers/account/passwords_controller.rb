class Account::PasswordsController < Account::BaseController
  RESET_NOTICE = "Password reset instructions were sent if that email has an account."

  allow_unauthenticated_customer_access
  rate_limit to: 5, within: 15.minutes, only: :create, with: -> { redirect_to new_account_session_path, notice: RESET_NOTICE }
  before_action :set_customer_by_token, only: %i[edit update]

  def new; end

  def create
    if (customer = Customer.find_by(email_address: params[:email_address].to_s.strip.downcase))
      CustomerMailer.password_reset(customer).deliver_later
    end

    redirect_to new_account_session_path, notice: RESET_NOTICE
  end

  def edit; end

  def update
    if @customer.update(params.permit(:password, :password_confirmation))
      @customer.customer_sessions.delete_all
      redirect_to new_account_session_path, notice: "Your password has been reset."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_customer_by_token
    @customer = Customer.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    redirect_to new_account_password_path, alert: "That password reset link is invalid or expired."
  end
end
