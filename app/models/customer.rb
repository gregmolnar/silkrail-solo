class Customer < ApplicationRecord
  has_secure_password
  has_many :customer_sessions, dependent: :destroy
  has_many :purchases, dependent: :nullify

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 10 }, if: -> { password.present? }

  def self.for_email(email)
    normalized_email = email.to_s.strip.downcase
    customer = find_or_create_by!(email_address: normalized_email) do |record|
      record.password = SecureRandom.base58(32)
    end
    Purchase.where(customer_id: nil).where("LOWER(email) = ?", normalized_email).update_all(customer_id: customer.id)
    customer
  end
end
