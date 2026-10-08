module CustomerAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_customer_authentication
    helper_method :customer_authenticated?
  end

  class_methods do
    def allow_unauthenticated_customer_access(**options)
      skip_before_action :require_customer_authentication, **options
      before_action :resume_customer_session, **options
    end
  end

  private

  def customer_authenticated?
    resume_customer_session.present?
  end

  def require_customer_authentication
    resume_customer_session || request_customer_authentication
  end

  def resume_customer_session
    Current.customer_session ||= CustomerSession.find_by(id: cookies.signed[:customer_session_id])
  end

  def request_customer_authentication
    session[:return_to_after_customer_authenticating] = request.fullpath if request.get? || request.head?
    redirect_to new_account_session_path
  end

  def start_customer_session_for(customer)
    customer.customer_sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |record|
      Current.customer_session = record
      cookies.signed.permanent[:customer_session_id] = { value: record.id, httponly: true, same_site: :lax, secure: Rails.env.production? }
    end
  end

  def terminate_customer_session
    Current.customer_session&.destroy
    Current.customer_session = nil
    cookies.delete(:customer_session_id)
  end
end
