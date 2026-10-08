require "test_helper"

class CustomerMailerTest < ActionMailer::TestCase
  test "password reset includes a valid reset link" do
    mail = CustomerMailer.password_reset(customers(:buyer))

    assert_equal [ "buyer@example.com" ], mail.to
    assert_match "Reset your Test Store password", mail.subject
    assert_match "/account/passwords/", mail.html_part.body.decoded
  end
end
