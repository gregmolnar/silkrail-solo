require "test_helper"

class Store::StylesheetsControllerTest < ActionDispatch::IntegrationTest
  test "serves general storefront CSS" do
    get store_styles_url

    assert_response :success
    assert_equal "text/css", response.media_type
    assert_includes response.body, "body.storefront-body"
    assert_includes response.body, ".product-card"
  end

  test "serves product-specific CSS" do
    product = products(:published)
    get store_product_styles_url(product.slug)

    assert_response :success
    assert_equal "text/css", response.media_type
    assert_includes response.body, ".product-page"
    assert_includes response.body, ".product-title"
  end
end
