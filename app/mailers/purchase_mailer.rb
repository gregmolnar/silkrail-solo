class PurchaseMailer < ApplicationMailer
  def receipt(purchase)
    @purchase = purchase
    @store = StoreSetting.current
    mail to: purchase.email, reply_to: @store.support_email.presence, subject: "Your #{@purchase.product.name} download"
  end

  def purchase_notification(purchase, owner)
    @purchase = purchase
    @store = StoreSetting.current
    mail to: owner.email_address, reply_to: @purchase.email, subject: "New purchase: #{@purchase.product.name}"
  end
end
