require "test_helper"

class DiscountCodeTest < ActiveSupport::TestCase
  test "normalizes and applies a code" do
    discount = products(:published).discount_codes.create!(code: " save20 ", percent_off: 20)
    assert_equal "SAVE20", discount.code
    assert_equal 1_520, discount.apply_to(1_900)
    assert discount.available?
  end

  test "expired code is unavailable" do
    discount = products(:published).discount_codes.create!(code: "OLD", percent_off: 10, expires_at: 1.hour.ago)
    assert_not discount.available?
  end
end
