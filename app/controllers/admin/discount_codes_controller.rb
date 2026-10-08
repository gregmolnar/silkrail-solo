class Admin::DiscountCodesController < ApplicationController
  before_action :set_product
  before_action :set_discount_code, only: %i[edit update destroy]

  def index
    @discount_codes = @product.discount_codes.order(created_at: :desc)
  end

  def new
    @discount_code = @product.discount_codes.new
  end

  def create
    @discount_code = @product.discount_codes.new(discount_code_params)
    if @discount_code.save
      redirect_to admin_product_discount_codes_path(@product), notice: "Discount code created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @discount_code.update(discount_code_params)
      redirect_to admin_product_discount_codes_path(@product), notice: "Discount code updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @discount_code.destroy!
    redirect_to admin_product_discount_codes_path(@product), notice: "Discount code deleted."
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def set_discount_code
    @discount_code = @product.discount_codes.find(params[:id])
  end

  def discount_code_params
    params.expect(discount_code: %i[code percent_off max_redemptions expires_at])
  end
end
