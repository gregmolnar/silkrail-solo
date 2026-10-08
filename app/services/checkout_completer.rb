class CheckoutCompleter
  def self.call(checkout)
    new(checkout).call
  end

  def initialize(checkout)
    @checkout = checkout
  end

  def call
    Purchase.transaction do
      return Purchase.find_by!(stripe_checkout_session_id: checkout.id) if Purchase.exists?(stripe_checkout_session_id: checkout.id)

      product = Product.find(checkout.metadata["product_id"])
      discount = DiscountCode.lock.find_by(id: checkout.metadata["discount_code_id"])
      email = checkout.customer_details&.email || checkout.customer_email
      customer = Customer.for_email(email)

      purchase = Purchase.create!(
        product: product,
        customer: customer,
        discount_code: discount,
        email: email,
        amount_cents: checkout.amount_total,
        currency: checkout.currency,
        stripe_checkout_session_id: checkout.id,
        stripe_payment_intent_id: checkout.payment_intent
      )
      discount&.increment!(:redemptions_count)
      PurchaseMailer.receipt(purchase).deliver_later
      purchase
    end
  end

  private

  attr_reader :checkout
end
