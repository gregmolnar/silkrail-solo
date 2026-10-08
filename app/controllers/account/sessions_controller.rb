class Account::SessionsController < Account::BaseController
  allow_unauthenticated_customer_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_account_session_path, alert: "Try again later." }

  def new; end

  def create
    if (customer = Customer.authenticate_by(email_address: params[:email_address], password: params[:password]))
      start_customer_session_for(customer)
      redirect_to session.delete(:return_to_after_customer_authenticating) || account_purchases_path
    else
      redirect_to new_account_session_path, alert: "Email or password is incorrect."
    end
  end

  def destroy
    terminate_customer_session
    redirect_to root_path
  end
end
