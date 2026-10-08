class CustomerMailer < ApplicationMailer
  def password_reset(customer)
    @customer = customer
    @store = StoreSetting.current
    mail to: customer.email_address, reply_to: @store.support_email.presence, subject: "Reset your #{@store.name} password"
  end
end
