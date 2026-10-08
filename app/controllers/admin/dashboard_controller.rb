class Admin::DashboardController < ApplicationController
  def show
    @revenue = Money.from_cents(Purchase.sum(:amount_cents), store.currency)
    @sales_count = Purchase.count
    @products_count = Product.count
    @recent_purchases = Purchase.includes(:product).order(created_at: :desc).limit(8)
  end
end
