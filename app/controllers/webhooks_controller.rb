class WebhooksController < ActionController::Base
  skip_forgery_protection

  def stripe
    event = Stripe::Webhook.construct_event(request.raw_post, request.headers["Stripe-Signature"], ENV.fetch("STRIPE_WEBHOOK_SECRET"))
    process_event(event) unless StripeEvent.exists?(stripe_id: event.id)
    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError, KeyError
    head :bad_request
  end

  private

  def process_event(event)
    StripeEvent.transaction do
      StripeEvent.create!(stripe_id: event.id, event_type: event.type, processed_at: Time.current)
      CheckoutCompleter.call(event.data.object) if event.type == "checkout.session.completed" && event.data.object.payment_status == "paid"
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end
end
