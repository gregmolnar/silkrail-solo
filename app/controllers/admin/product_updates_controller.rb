class Admin::ProductUpdatesController < ApplicationController
  before_action :set_product

  def index
    @product_updates = @product.product_updates.order(created_at: :desc)
  end

  def new
    @product_update = @product.product_updates.new
  end

  def create
    @product_update = @product.product_updates.new(product_update_params)
    if @product_update.save
      ProductUpdateDeliveryJob.perform_later(@product_update)
      redirect_to admin_product_product_updates_path(@product), notice: "Product update queued for #{@product.purchases.distinct.count(:email)} customers."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def product_update_params
    params.expect(product_update: %i[subject body])
  end
end
