class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern
  before_action :resume_customer_identity

  helper_method :store

  private

  def store
    @store ||= StoreSetting.current
  end

  def resume_customer_identity
    Current.customer_session ||= CustomerSession.find_by(id: cookies.signed[:customer_session_id])
  end
end
