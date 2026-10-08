class Store::ProductsController < ApplicationController
  allow_unauthenticated_access
  layout "store"

  def show
    @product = Product.find_by!(slug: params[:slug])
    raise ActiveRecord::RecordNotFound unless @product.published? || authenticated?

    @author_name = User.order(:created_at).pick(:name).presence || store.name
    @testimonials = Testimonials::Testimonial.publishable.featured_first.limit(6)
  end
end
