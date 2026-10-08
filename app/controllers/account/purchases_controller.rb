class Account::PurchasesController < Account::BaseController
  def index
    @purchases = Current.customer.purchases.includes(:product).order(created_at: :desc)
  end
end
