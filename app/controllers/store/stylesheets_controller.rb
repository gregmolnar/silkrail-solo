class Store::StylesheetsController < ActionController::Base
  def store
    stylesheet(StoreSetting.current.custom_css)
  end

  def product
    stylesheet(Product.find_by!(slug: params[:slug]).custom_css)
  end

  private

  def stylesheet(css)
    expires_in 5.minutes, public: true
    render plain: css, content_type: "text/css; charset=utf-8"
  end
end
