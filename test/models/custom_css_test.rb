require "test_helper"

class CustomCssTest < ActiveSupport::TestCase
  test "new store settings include documented CSS selectors" do
    css = StoreSetting.new.custom_css

    assert_includes css, ".store-header"
    assert_includes css, ".product-card"
  end

  test "new products include documented product page selectors" do
    css = Product.new.custom_css

    assert_includes css, ".product-layout"
    assert_includes css, ".buy-button"
  end
end
