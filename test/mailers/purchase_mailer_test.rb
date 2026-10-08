require "test_helper"

class PurchaseMailerTest < ActionMailer::TestCase
  test "purchase notification goes to the owner" do
    purchase = purchases(:buyer)
    owner = users(:owner)

    mail = PurchaseMailer.purchase_notification(purchase, owner)

    assert_equal [ owner.email_address ], mail.to
    assert_equal [ purchase.email ], mail.reply_to
    assert_equal "New purchase: #{purchase.product.name}", mail.subject
    assert_match purchase.email, mail.text_part.body.decoded
    assert_match "/admin/purchases/#{purchase.id}", mail.text_part.body.decoded
  end
end
