class StoreSetting < ApplicationRecord
  has_rich_text :privacy_policy
  has_rich_text :terms_of_service
  has_rich_text :refund_policy
  has_rich_text :seller_information

  validates :name, :currency, presence: true
  validates :currency, format: { with: /\A[a-zA-Z]{3}\z/ }
  validates :support_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :stripe_tax_behavior, inclusion: { in: %w[inclusive exclusive] }

  before_validation { self.currency = currency.to_s.downcase }

  def self.current
    first_or_create!
  end
end
