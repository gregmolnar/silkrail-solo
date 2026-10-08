require "test_helper"

class Store::CheckoutsControllerTest < ActionDispatch::IntegrationTest
  test "passes Stripe a success URL with its literal session placeholder" do
    submitted = capture_checkout_attributes

    assert_response :see_other
    assert submitted[:success_url].ends_with?("?session_id={CHECKOUT_SESSION_ID}")
    assert_not_includes submitted[:success_url], "%7B"
  end

  test "does not request Stripe Tax when it is disabled" do
    submitted = capture_checkout_attributes

    assert_equal "auto", submitted[:billing_address_collection]
    assert_not submitted.key?(:automatic_tax)
    assert_not submitted.key?(:tax_id_collection)
    assert_not submitted.key?(:invoice_creation)
    assert_not submitted.dig(:line_items, 0, :price_data).key?(:tax_behavior)
  end

  test "requests automatic tax and invoices when Stripe Tax is enabled" do
    store_settings(:store).update!(stripe_tax_enabled: true, stripe_tax_behavior: "exclusive")

    submitted = capture_checkout_attributes

    assert_equal "required", submitted[:billing_address_collection]
    assert_equal({ enabled: true }, submitted[:automatic_tax])
    assert_equal({ enabled: true }, submitted[:tax_id_collection])
    assert_equal({ enabled: true }, submitted[:invoice_creation])
    assert_equal "exclusive", submitted.dig(:line_items, 0, :price_data, :tax_behavior)
  end

  private

  def capture_checkout_attributes
    submitted = nil
    original_create = Stripe::Checkout::Session.method(:create)
    Stripe::Checkout::Session.define_singleton_method(:create) do |attributes|
      submitted = attributes
      Struct.new(:url).new("https://checkout.stripe.test/session")
    end

    post store_checkout_url(products(:published))
    submitted
  ensure
    Stripe::Checkout::Session.define_singleton_method(:create, original_create)
  end
end
