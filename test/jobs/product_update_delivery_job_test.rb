require "test_helper"

class ProductUpdateDeliveryJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "queues one email per unique product customer" do
    update = product_updates(:announcement)

    assert_enqueued_emails 1 do
      ProductUpdateDeliveryJob.perform_now(update)
    end
    assert update.reload.sent_at?
  end

  test "does not queue an update twice" do
    update = product_updates(:announcement)
    update.update!(sent_at: Time.current)

    assert_no_enqueued_emails { ProductUpdateDeliveryJob.perform_now(update) }
  end
end
