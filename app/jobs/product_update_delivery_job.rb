class ProductUpdateDeliveryJob < ApplicationJob
  queue_as :default

  def perform(product_update)
    product_update.with_lock do
      return if product_update.sent_at?

      product_update.product.purchases.distinct.pluck(:email).each do |email|
        ProductUpdateMailer.announcement(product_update, email).deliver_later
      end
      product_update.update!(sent_at: Time.current)
    end
  end
end
