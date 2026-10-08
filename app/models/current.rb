class Current < ActiveSupport::CurrentAttributes
  attribute :session, :customer_session
  delegate :user, to: :session, allow_nil: true
  delegate :customer, to: :customer_session, allow_nil: true
end
