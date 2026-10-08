require "test_helper"

class Account::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "customer signs in and sees purchases" do
    post account_session_url, params: { email_address: customers(:buyer).email_address, password: "customer-password" }

    assert_redirected_to account_purchases_url
    follow_redirect!
    assert_response :success
    assert_select "h2", text: products(:published).name
  end

  test "purchases require customer authentication" do
    get account_purchases_url
    assert_redirected_to new_account_session_url
  end
end
