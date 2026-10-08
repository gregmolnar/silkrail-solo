require "test_helper"

class ProductUpdateMailerTest < ActionMailer::TestCase
  test "announcement renders for a customer" do
    mail = ProductUpdateMailer.announcement(product_updates(:announcement), customers(:buyer).email_address)

    assert_equal [ "buyer@example.com" ], mail.to
    assert_equal "A new version is ready", mail.subject
    assert_match "Download the latest files", mail.html_part.body.decoded
    assert_match "/account/purchases", mail.html_part.body.decoded
  end
end
