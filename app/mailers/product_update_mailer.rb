class ProductUpdateMailer < ApplicationMailer
  def announcement(product_update, email)
    @product_update = product_update
    @product = product_update.product
    @store = StoreSetting.current
    @customer = Customer.find_by(email_address: email)
    mail to: email, reply_to: @store.support_email.presence, subject: product_update.subject
  end
end
