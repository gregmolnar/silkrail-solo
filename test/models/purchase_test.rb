require "test_helper"

class PurchaseTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "queues an owner email when purchase notifications are enabled" do
    store_settings(:store).update!(purchase_notifications_enabled: true)

    assert_enqueued_emails 1 do
      products(:published).purchases.create!(
        email: "notification@example.com",
        amount_cents: 2_500,
        currency: "usd",
        source: :manual,
        external_id: "notification-enabled"
      )
    end
  end

  test "does not queue an owner email when purchase notifications are disabled" do
    store_settings(:store).update!(purchase_notifications_enabled: false)

    assert_enqueued_emails 0 do
      products(:published).purchases.create!(
        email: "quiet@example.com",
        amount_cents: 2_500,
        currency: "usd",
        source: :manual,
        external_id: "notification-disabled"
      )
    end
  end
end
