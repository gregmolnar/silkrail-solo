require "test_helper"

class TestimonialsIntegrationTest < ActionDispatch::IntegrationTest
  test "approved public testimonials appear on product pages" do
    approved = Testimonials::Testimonial.create!(
      body: "This course changed how I review Rails code.",
      rating: 5,
      name: "A Customer",
      status: "approved",
      consent_given: true
    )
    Testimonials::Testimonial.create!(body: "Still pending", status: "pending", consent_given: true)

    get store_product_url(products(:published).slug)

    assert_response :success
    assert_select ".testimonial-card", count: 1
    assert_select ".testimonial-quote", text: /#{Regexp.escape(approved.body)}/
    assert_select ".testimonial-stars", text: /★★★★★/
    assert_select ".testimonial-author", text: /A Customer/
  end

  test "purchase page can open the testimonial widget" do
    get purchase_url(purchases(:buyer).access_token)

    assert_response :success
    assert_select "button[data-testimonial-prompt]", text: "Leave a review"
    assert_select "script[data-testimonials-config]"
  end

  test "testimonial dashboard requires an owner session" do
    get "/testimonials"
    assert_response :forbidden

    post "/session", params: { email_address: users(:owner).email_address, password: "correct-horse-battery" }
    assert_response :redirect

    get "/testimonials"
    assert_response :success
  end
end
