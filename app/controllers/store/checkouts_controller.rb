class Store::CheckoutsController < ApplicationController
  allow_unauthenticated_access

  def create
    product = Product.published.find(params[:product_id])
    discount = find_discount(product)
    if params[:discount_code].present? && discount.nil?
      return redirect_to store_product_path(product.slug), alert: "That discount code is invalid or expired."
    end
    amount = discount ? discount.apply_to(product.price_cents) : product.price_cents

    metadata = { product_id: product.id.to_s }
    metadata[:discount_code_id] = discount.id.to_s if discount

    checkout = Stripe::Checkout::Session.create(checkout_attributes(product, amount, metadata))
    redirect_to checkout.url, allow_other_host: true, status: :see_other
  rescue Stripe::StripeError => error
    redirect_to store_product_path(product.slug), alert: "Stripe could not start checkout: #{error.message}"
  end

  def success
    checkout = Stripe::Checkout::Session.retrieve(params[:session_id])
    @purchase = CheckoutCompleter.call(checkout) if checkout.payment_status == "paid"
    render layout: "store"
  rescue Stripe::StripeError, ActiveRecord::RecordNotFound => error
    Rails.logger.error("Checkout verification failed: #{error.class}: #{error.message}")
    redirect_to root_path, alert: "We could not verify that purchase yet. Please contact support if you were charged."
  end

  private

  def checkout_attributes(product, amount, metadata)
    price_data = { currency: store.currency, unit_amount: amount, product_data: product.stripe_product_data }
    price_data[:tax_behavior] = store.stripe_tax_behavior if store.stripe_tax_enabled?

    {
      mode: "payment",
      line_items: [ { price_data: price_data, quantity: 1 } ],
      metadata: metadata,
      # Stripe only substitutes the placeholder when the braces are literal.
      # Passing it through a Rails URL helper query hash percent-encodes them.
      success_url: "#{success_store_checkouts_url}?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: store_product_url(product.slug),
      customer_creation: "always",
      billing_address_collection: store.stripe_tax_enabled? ? "required" : "auto"
    }.tap do |attributes|
      if store.stripe_tax_enabled?
        attributes[:automatic_tax] = { enabled: true }
        attributes[:tax_id_collection] = { enabled: true }
        attributes[:invoice_creation] = { enabled: true }
      end
    end
  end

  def find_discount(product)
    return if params[:discount_code].blank?

    product.discount_codes.available.find_by("UPPER(code) = ?", params[:discount_code].strip.upcase)
  end
end
