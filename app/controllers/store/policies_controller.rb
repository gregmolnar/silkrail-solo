class Store::PoliciesController < ApplicationController
  POLICIES = {
    "privacy" => [ "Privacy policy", :privacy_policy ],
    "terms" => [ "Terms of service", :terms_of_service ],
    "refunds" => [ "Refund policy", :refund_policy ],
    "seller" => [ "Seller/contact information", :seller_information ]
  }.freeze

  allow_unauthenticated_access
  layout "store"

  def show
    @title, attribute = POLICIES.fetch(params[:policy]) { raise ActiveRecord::RecordNotFound }
    @content = store.public_send(attribute)
    raise ActiveRecord::RecordNotFound unless @content.present?
  end
end
