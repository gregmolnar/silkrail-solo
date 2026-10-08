class Admin::PurchasesController < ApplicationController
  before_action :set_purchase, only: %i[show revoke_access_token regenerate_download_token]

  def index
    @purchases = Purchase.includes(:product).order(created_at: :desc)
    if params[:product_id].present?
      @product = Product.find(params[:product_id])
      @purchases = @purchases.where(product: @product)
    end
  end

  def show
    @latest_release = @purchase.product.releases.published.with_attached_files.order(created_at: :desc).first
  end

  def revoke_access_token
    @purchase.revoke_access_token!
    redirect_to admin_purchase_path(@purchase), notice: "Download access has been revoked."
  end

  def regenerate_download_token
    @purchase.regenerate_download_token!
    redirect_to admin_purchase_path(@purchase), notice: "A new download token has been generated."
  end

  private

  def set_purchase
    @purchase = Purchase.find(params[:id])
  end
end
