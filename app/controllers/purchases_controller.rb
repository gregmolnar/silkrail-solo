class PurchasesController < ApplicationController
  allow_unauthenticated_access
  layout "store"
  rate_limit to: 30, within: 1.minute, only: :download
  before_action :set_purchase

  def show
    @latest_release = @purchase.product.releases.published.with_attached_files.order(created_at: :desc).first
  end

  def download
    attachment = @purchase.product.releases.published.joins(:files_attachments).find_by!(active_storage_attachments: { id: params[:attachment_id] }).files.attachments.find(params[:attachment_id])
    redirect_to rails_blob_path(attachment, disposition: "attachment"), allow_other_host: false
  end

  private

  def set_purchase
    @purchase = Purchase.where(access_token_revoked_at: nil).find_by!(access_token: params[:token])
  end
end
