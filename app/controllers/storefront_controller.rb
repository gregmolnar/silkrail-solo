class StorefrontController < ApplicationController
  allow_unauthenticated_access
  layout "store"

  def index
    @products = Product.published.order(created_at: :desc)
  end
end
