require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "description is stored as rich text" do
    product = products(:published)

    product.update!(description: "<p>A <strong>rich</strong> description.</p>")

    assert_equal "<p>A <strong>rich</strong> description.</p>", product.description.body.to_html
  end

  test "Stripe product data omits an empty description" do
    product = products(:published)
    product.summary = nil

    assert_equal({ name: product.name }, product.stripe_product_data)
  end

  test "Stripe product data includes and truncates a description" do
    product = products(:published)
    product.summary = "a" * 600

    assert_equal product.name, product.stripe_product_data[:name]
    assert_equal 500, product.stripe_product_data[:description].length
  end
end
