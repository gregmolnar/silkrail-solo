require "test_helper"

class AdminPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_url, params: { email_address: users(:owner).email_address, password: "correct-horse-battery" }
  end

  test "owner can render the management pages" do
    product = products(:published)
    release = releases(:published)

    [
      admin_root_url,
      admin_products_url,
      new_admin_product_url,
      edit_admin_product_url(product),
      admin_product_releases_url(product),
      new_admin_product_release_url(product),
      edit_admin_product_release_url(product, release),
      admin_product_discount_codes_url(product),
      new_admin_product_discount_code_url(product),
      admin_product_product_updates_url(product),
      new_admin_product_product_update_url(product),
      admin_purchases_url,
      admin_purchase_url(purchases(:buyer)),
      edit_admin_settings_url
    ].each do |url|
      get url
      assert_response :success, url
    end
  end

  test "owner can revoke purchase download access" do
    purchase = purchases(:buyer)

    patch revoke_access_token_admin_purchase_url(purchase)

    assert_redirected_to admin_purchase_url(purchase)
    assert purchase.reload.access_token_revoked?
  end

  test "owner can replace a purchase download token" do
    purchase = purchases(:buyer)
    old_token = purchase.access_token
    purchase.revoke_access_token!

    patch regenerate_download_token_admin_purchase_url(purchase)

    assert_redirected_to admin_purchase_url(purchase)
    purchase.reload
    assert_not purchase.access_token_revoked?
    assert_not_equal old_token, purchase.access_token

    get purchase_url(old_token)
    assert_response :not_found
    get purchase_url(purchase.access_token)
    assert_response :success
  end

  test "settings form uses Lexxy editors for policies and seller information" do
    get edit_admin_settings_url

    assert_response :success
    %w[privacy_policy terms_of_service refund_policy seller_information].each do |field|
      assert_select "lexxy-editor[name='store_setting[#{field}]']"
    end
    assert_select "input[type='checkbox'][name='store_setting[purchase_notifications_enabled]']"
  end

  test "owner can update policies and seller information" do
    params = settings_params
    params[:store_setting].merge!(
      privacy_policy: "<p>Private data details</p>",
      terms_of_service: "<p>Store terms</p>",
      refund_policy: "<p>Refund details</p>",
      seller_information: "<p>Example Seller LLC</p>"
    )

    patch admin_settings_url, params: params

    assert_redirected_to edit_admin_settings_url
    settings = store_settings(:store).reload
    assert_includes settings.privacy_policy.to_plain_text, "Private data details"
    assert_includes settings.terms_of_service.to_plain_text, "Store terms"
    assert_includes settings.refund_policy.to_plain_text, "Refund details"
    assert_includes settings.seller_information.to_plain_text, "Example Seller LLC"
  end

  test "product pages link to the Gumroad sales importer" do
    product = products(:published)

    get admin_products_url
    assert_select "a[href=?]", import_admin_product_purchases_path(product), text: "Import Gumroad"
    assert_select "a[href=?]", new_admin_product_purchase_path(product), text: "Add purchase"

    get edit_admin_product_url(product)
    assert_select "a[href=?]", import_admin_product_purchases_path(product), text: "Import Gumroad sales"
    assert_select "a[href=?]", new_admin_product_purchase_path(product), text: "Add purchase"
  end

  test "release form uses Lexxy and Active Storage direct uploads" do
    get new_admin_product_release_url(products(:published))

    assert_response :success
    assert_select "lexxy-editor[name='release[notes]']"
    assert_select "input[type='file'][name='release[files][]'][data-direct-upload-url]"
  end

  test "product update form uses Lexxy" do
    get new_admin_product_product_update_url(products(:published))

    assert_response :success
    assert_select "lexxy-editor[name='product_update[body]']"
  end

  test "product form uses the Lexxy description editor" do
    get edit_admin_product_url(products(:published))

    assert_response :success
    assert_select "lexxy-editor[name='product[description]']"
  end

  test "failed product creation can re-render an uploaded cover" do
    cover = fixture_file_upload("product-cover.png", "image/png")

    post admin_products_url, params: {
      product: { name: "", status: "draft", price: "10.00", cover: cover }
    }

    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "settings update without changing the password" do
    patch admin_settings_url, params: settings_params(store_name: "Updated Store")

    assert_redirected_to edit_admin_settings_url
    assert_equal "Updated Store", store_settings(:store).reload.name
    assert users(:owner).reload.authenticate("correct-horse-battery")
  end

  test "password change requires the existing password" do
    patch admin_settings_url,
      params: settings_params(
        password: "a-new-secure-password",
        password_confirmation: "a-new-secure-password",
        current_password: "wrong-password"
      ),
      headers: { "Accept" => Mime[:turbo_stream].to_s }

    assert_response :unprocessable_entity
    assert users(:owner).reload.authenticate("correct-horse-battery")
  end

  test "password can be changed with the existing password" do
    patch admin_settings_url, params: settings_params(
      password: "a-new-secure-password",
      password_confirmation: "a-new-secure-password",
      current_password: "correct-horse-battery"
    )

    assert_redirected_to edit_admin_settings_url
    assert users(:owner).reload.authenticate("a-new-secure-password")
  end

  test "jobs dashboard is available to the owner" do
    get "/jobs"

    assert_response :success
  end

  test "admin requires authentication" do
    delete session_url
    get admin_products_url
    assert_redirected_to new_session_url
  end

  test "jobs dashboard requires authentication" do
    delete session_url
    get "/jobs"

    assert_response :redirect
    assert_equal "/session/new", URI(response.location).path
  end

  private

  def settings_params(store_name: store_settings(:store).name, password: "", password_confirmation: "", current_password: "")
    {
      store_setting: {
        name: store_name,
        description: store_settings(:store).description,
        support_email: store_settings(:store).support_email,
        currency: store_settings(:store).currency,
        custom_css: store_settings(:store).custom_css,
        stripe_tax_enabled: store_settings(:store).stripe_tax_enabled,
        stripe_tax_behavior: store_settings(:store).stripe_tax_behavior,
        purchase_notifications_enabled: store_settings(:store).purchase_notifications_enabled
      },
      user: {
        name: users(:owner).name,
        email_address: users(:owner).email_address,
        password: password,
        password_confirmation: password_confirmation,
        current_password: current_password
      }
    }
  end
end
