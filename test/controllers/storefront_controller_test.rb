require "test_helper"

class StorefrontControllerTest < ActionDispatch::IntegrationTest
  test "product page includes Open Graph metadata" do
    product = products(:published)
    product.cover.attach(
      io: file_fixture("product-cover.png").open,
      filename: "product-cover.png",
      content_type: "image/png"
    )

    get store_product_url(product.slug)

    assert_response :success
    assert_select "meta[property='og:type'][content='product']"
    assert_select "meta[property='og:title'][content=?]", product.name
    assert_select "meta[property='og:description'][content=?]", product.summary
    assert_select "meta[property='og:url'][content=?]", store_product_url(product.slug)
    assert_select "meta[property='og:image'][content^='http'][content*='/rails/active_storage/']"
    assert_select "meta[property='og:image:alt'][content=?]", product.name
  end

  test "product page uses a hero and two-column purchase layout" do
    product = products(:published)
    product.cover.attach(
      io: file_fixture("product-cover.png").open,
      filename: "product-cover.png",
      content_type: "image/png"
    )

    get store_product_url(product.slug)

    assert_response :success
    assert_select ".product-hero .product-cover.aspect-\\[3\\/1\\]"
    assert_select ".product-layout .product-details .product-title", text: product.name
    assert_select ".product-meta .product-price"
    assert_select ".product-meta .product-author", text: /By Owner/
    assert_select ".product-details .product-description"
    assert_select ".product-layout .product-purchase-sidebar .buy-button", value: "Buy now"
  end

  test "storefront includes the site Open Graph image" do
    get root_url

    assert_response :success
    assert_select "meta[property='og:title'][content=?]", store_settings(:store).name
    assert_select "meta[property='og:image'][content^='http'][content*='og-image']"
    assert_select "meta[property='og:image:width'][content='1200']"
    assert_select "meta[property='og:image:height'][content='630']"
  end

  test "shows only published products" do
    get root_url
    assert_response :success
    assert_select "h2", text: products(:published).name
    assert_select "h2", text: products(:draft).name, count: 0
  end
end
