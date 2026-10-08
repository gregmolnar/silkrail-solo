require "test_helper"

class PurchasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @purchase = purchases(:buyer)
    @latest_release = releases(:published)
    @latest_release.update!(created_at: Time.current)
    @latest_release.files.attach(
      io: StringIO.new("latest release contents"),
      filename: "field-guide.pdf",
      content_type: "application/pdf"
    )

    older = @purchase.product.releases.create!(name: "Older version", status: :published, created_at: 1.day.ago)
    older.files.attach(io: StringIO.new("old"), filename: "old.pdf", content_type: "application/pdf")
  end

  test "shows downloads from only the latest published release" do
    file = @latest_release.files.first

    get purchase_url(@purchase.access_token)

    assert_response :success
    assert_select "h2", text: @latest_release.name
    assert_select "a[href=?]", purchase_download_path(@purchase.access_token, file.id), text: /Download field-guide\.pdf/
    assert_select "a[href=?] span", purchase_download_path(@purchase.access_token, file.id), text: "23 Bytes"
    assert_select "h2", text: "Older version", count: 0
  end

  test "revoked token cannot open purchase or download files" do
    file = @latest_release.files.first
    token = @purchase.access_token
    @purchase.revoke_access_token!

    get purchase_url(token)
    assert_response :not_found

    get purchase_download_url(token, file.id)
    assert_response :not_found
  end

  test "downloads are rate limited by IP address" do
    file = @latest_release.files.first

    store = PurchasesController.cache_store
    original_increment = store.method(:increment)
    store.define_singleton_method(:increment) { |*, **| 31 }

    get purchase_download_url(@purchase.access_token, file.id)

    assert_response :too_many_requests
  ensure
    store&.define_singleton_method(:increment, original_increment) if original_increment
  end

  test "latest release file can be downloaded" do
    file = @latest_release.files.first

    get purchase_download_url(@purchase.access_token, file.id)

    assert_response :redirect
    assert_includes response.location, "/rails/active_storage/"
  end
end
