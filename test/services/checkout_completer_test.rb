require "test_helper"

class CheckoutCompleterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  test "links a repeat buyer to their existing customer account" do
    customer = customers(:buyer)
    checkout = Stripe::Checkout::Session.construct_from(
      id: "cs_test_repeat_buyer",
      metadata: { product_id: products(:published).id.to_s },
      customer_details: { email: customer.email_address.upcase },
      amount_total: 1_900,
      currency: "usd",
      payment_intent: "pi_test_repeat_buyer"
    )

    assert_no_difference "Customer.count" do
      purchase = CheckoutCompleter.call(checkout)
      assert_equal customer, purchase.customer
    end
  end

  test "fulfills a paid checkout exactly once" do
    checkout = Stripe::Checkout::Session.construct_from(
      id: "cs_test_new",
      metadata: { product_id: products(:published).id.to_s },
      customer_details: { email: "NEW-BUYER@example.com" },
      amount_total: 1_900,
      currency: "usd",
      payment_intent: "pi_test_new"
    )

    assert_enqueued_emails 1 do
      purchase = CheckoutCompleter.call(checkout)
      assert_equal "new-buyer@example.com", purchase.email
      assert_equal "new-buyer@example.com", purchase.customer.email_address
      assert_equal 1_900, purchase.amount_cents
    end

    assert_no_enqueued_emails { assert_equal Purchase.find_by!(stripe_checkout_session_id: checkout.id), CheckoutCompleter.call(checkout) }
  end
end
