require "test_helper"

class Store::PoliciesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @store = store_settings(:store)
    @store.update!(
      privacy_policy: "<p>How we handle data.</p>",
      terms_of_service: "<p>The store terms.</p>",
      refund_policy: "<p>Our refund rules.</p>",
      seller_information: "<p>Example Seller LLC</p>"
    )
  end

  test "renders configured policy pages" do
    {
      privacy_policy_url => [ "Privacy policy", "How we handle data." ],
      terms_of_service_url => [ "Terms of service", "The store terms." ],
      refund_policy_url => [ "Refund policy", "Our refund rules." ],
      seller_information_url => [ "Seller/contact information", "Example Seller LLC" ]
    }.each do |url, (title, content)|
      get url

      assert_response :success
      assert_select "h1", title
      assert_includes response.body, content
    end
  end

  test "storefront footer links to configured policies" do
    get root_url

    assert_select "a[href=?]", privacy_policy_path, text: "Privacy"
    assert_select "a[href=?]", terms_of_service_path, text: "Terms"
    assert_select "a[href=?]", refund_policy_path, text: "Refund policy"
    assert_select "a[href=?]", seller_information_path, text: "Seller information"
  end

  test "blank policies are not published" do
    @store.update!(privacy_policy: "")

    get privacy_policy_url

    assert_response :not_found
  end
end
