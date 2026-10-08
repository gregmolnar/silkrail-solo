Rails.application.routes.draw do
  mount_testimonials at: "/testimonials"
  root "storefront#index"

  resource :session, only: %i[new create destroy]

  namespace :account do
    resource :session, only: %i[new create destroy]
    resources :passwords, param: :token, only: %i[new create edit update]
    resources :purchases, only: :index
  end
  get "store.css", to: "store/stylesheets#store", as: :store_styles
  get "privacy", to: "store/policies#show", defaults: { policy: "privacy" }, as: :privacy_policy
  get "terms", to: "store/policies#show", defaults: { policy: "terms" }, as: :terms_of_service
  get "refund-policy", to: "store/policies#show", defaults: { policy: "refunds" }, as: :refund_policy
  get "seller-information", to: "store/policies#show", defaults: { policy: "seller" }, as: :seller_information
  get "products/:slug/styles.css", to: "store/stylesheets#product", as: :store_product_styles
  get "products/:slug", to: "store/products#show", as: :store_product
  post "products/:product_id/checkout", to: "store/checkouts#create", as: :store_checkout
  get "checkout/success", to: "store/checkouts#success", as: :success_store_checkouts
  get "purchases/:token", to: "purchases#show", as: :purchase
  get "purchases/:token/download/:attachment_id", to: "purchases#download", as: :purchase_download
  post "webhooks/stripe", to: "webhooks#stripe"

  namespace :admin do
    root "dashboard#show"
    resource :settings, only: %i[edit update]
    resources :products, except: :show do
      resources :releases, except: :show
      resources :discount_codes, except: :show
      resources :product_updates, only: %i[index new create]
      resources :purchases, only: %i[new create], controller: "product_purchases" do
        collection do
          get :import
          post :import, action: :import_create
        end
      end
    end
    resources :purchases, only: %i[index show] do
      member do
        patch :revoke_access_token
        patch :regenerate_download_token
      end
    end
  end

  mount MissionControl::Jobs::Engine, at: "/jobs"
  get "up" => "rails/health#show", as: :rails_health_check
end
