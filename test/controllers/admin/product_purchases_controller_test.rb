require "test_helper"

class Admin::ProductPurchasesControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    post session_url, params: { email_address: users(:owner).email_address, password: "correct-horse-battery" }
    @product = products(:published)
  end

  test "renders manual purchase form" do
    get new_admin_product_purchase_url(@product)

    assert_response :success
    assert_select "form[action=?]", admin_product_purchases_path(@product)
    assert_select "input[name='purchase[email]']"
    assert_select "input[name='purchase[amount]'][value='19.00']"
    assert_select "select[name='purchase[source]'] option[selected][value='manual']"
    assert_select "select[name='purchase[source]'] option[value='gumroad']"
    assert_select "select[name='purchase[source]'] option[value='stripe']", count: 0
  end

  test "manually adds a purchase and optionally sends its receipt" do
    purchased_at = "2026-01-02T12:30"

    assert_difference -> { @product.purchases.manual.count }, 1 do
      assert_enqueued_emails 1 do
        post admin_product_purchases_url(@product), params: {
          purchase: {
            email: "MANUAL@example.com",
            amount: "12.50",
            source: "manual",
            purchased_at: purchased_at,
            external_id: "support-order-123",
            send_receipt: "1"
          }
        }
      end
    end

    purchase = @product.purchases.manual.find_by!(external_id: "support-order-123")
    assert_redirected_to admin_purchase_url(purchase)
    assert_equal "manual@example.com", purchase.email
    assert_equal 1_250, purchase.amount_cents
    assert_equal "usd", purchase.currency
    assert_equal Time.zone.parse(purchased_at), purchase.created_at
    assert_equal purchase.customer, Customer.find_by!(email_address: "manual@example.com")
  end

  test "manually added purchase can use the Gumroad source" do
    post admin_product_purchases_url(@product), params: {
      purchase: {
        email: "gumroad-manual@example.com",
        amount: "9.00",
        source: "gumroad",
        purchased_at: "",
        external_id: "gumroad-support-order",
        send_receipt: "0"
      }
    }

    purchase = @product.purchases.find_by!(external_id: "gumroad-support-order")
    assert purchase.gumroad?
    assert_redirected_to admin_purchase_url(purchase)
  end

  test "does not create a customer for an invalid manual purchase" do
    assert_no_difference [ "Purchase.count", "Customer.count" ] do
      post admin_product_purchases_url(@product), params: {
        purchase: { email: "not-an-email", amount: "12.50", source: "manual", purchased_at: "", external_id: "", send_receipt: "0" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "renders Gumroad import form" do
    get import_admin_product_purchases_url(@product)
    assert_response :success
    assert_select "input[type=file][name=gumroad_csv]"
  end

  test "imports matching Gumroad purchases" do
    csv = fixture_file_upload("gumroad_sales.csv", "text/csv")

    assert_difference -> { @product.purchases.gumroad.count }, 2 do
      post import_admin_product_purchases_url(@product), params: { gumroad_csv: csv }
    end

    assert_redirected_to admin_purchases_url(product_id: @product)
    purchase = @product.purchases.find_by!(external_id: "sale-one")
    assert_equal "buyer-one@example.com", purchase.email
    assert_equal 1_900, purchase.amount_cents
    assert_equal "usd", purchase.currency
    assert_equal Time.zone.parse("2025-06-10 14:30:00"), purchase.created_at
  end

  test "skips purchases already imported by Gumroad sale ID" do
    @product.purchases.create!(email: "buyer-one@example.com", amount_cents: 1_900, currency: "usd", source: "gumroad", external_id: "sale-one")
    csv = fixture_file_upload("gumroad_sales.csv", "text/csv")

    assert_difference -> { @product.purchases.gumroad.count }, 1 do
      post import_admin_product_purchases_url(@product), params: { gumroad_csv: csv }
    end
  end
end
