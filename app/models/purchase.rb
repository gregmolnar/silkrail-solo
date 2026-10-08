class Purchase < ApplicationRecord
  belongs_to :product
  belongs_to :discount_code, optional: true
  belongs_to :customer, optional: true

  enum :source, { stripe: "stripe", gumroad: "gumroad", manual: "manual" }, validate: true
  has_secure_token :access_token, length: 32
  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :stripe_checkout_session_id, presence: true, uniqueness: true, if: -> { source == "stripe" }
  validates :external_id, uniqueness: { scope: :source }, allow_nil: true

  after_create_commit :send_owner_notification

  def amount
    Money.from_cents(amount_cents, currency)
  end

  def access_token_revoked?
    access_token_revoked_at.present?
  end

  def revoke_access_token!
    update!(access_token_revoked_at: Time.current)
  end

  def regenerate_download_token!
    with_lock do
      regenerate_access_token
      update!(access_token_revoked_at: nil)
    end
  end

  private

  def send_owner_notification
    return unless StoreSetting.current.purchase_notifications_enabled?
    return unless (owner = User.order(:created_at).first)

    PurchaseMailer.purchase_notification(self, owner).deliver_later
  end
end
