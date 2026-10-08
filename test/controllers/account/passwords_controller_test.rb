require "test_helper"

class Account::PasswordsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  test "customer can request and use a password reset" do
    customer = customers(:buyer)

    assert_enqueued_emails 1 do
      post account_passwords_url, params: { email_address: customer.email_address }
    end
    assert_redirected_to new_account_session_url

    token = customer.password_reset_token
    get edit_account_password_url(token)
    assert_response :success

    put account_password_url(token), params: { password: "new-customer-password", password_confirmation: "new-customer-password" }
    assert_redirected_to new_account_session_url
    assert customer.reload.authenticate("new-customer-password")
  end

  test "password reset requests are rate limited without revealing the account" do
    store = Account::PasswordsController.cache_store
    original_increment = store.method(:increment)
    store.define_singleton_method(:increment) { |*, **| 6 }

    assert_no_enqueued_emails do
      post account_passwords_url, params: { email_address: customers(:buyer).email_address }
    end

    assert_redirected_to new_account_session_url
    assert_equal Account::PasswordsController::RESET_NOTICE, flash[:notice]
  ensure
    store&.define_singleton_method(:increment, original_increment) if original_increment
  end

  test "unknown email receives the same response" do
    assert_no_enqueued_emails do
      post account_passwords_url, params: { email_address: "unknown@example.com" }
    end
    assert_redirected_to new_account_session_url
  end
end
