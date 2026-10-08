class DiscountCode < ApplicationRecord
  belongs_to :product
  has_many :purchases, dependent: :nullify

  normalizes :code, with: ->(code) { code.strip.upcase }
  validates :code, presence: true, uniqueness: { scope: :product_id, case_sensitive: false }
  validates :percent_off, inclusion: { in: 1..100 }
  validates :max_redemptions, numericality: { greater_than: 0, allow_nil: true }

  scope :available, -> { where("expires_at IS NULL OR expires_at > ?", Time.current).where("max_redemptions IS NULL OR redemptions_count < max_redemptions") }

  def available?
    (expires_at.nil? || expires_at.future?) && (max_redemptions.nil? || redemptions_count < max_redemptions)
  end

  def apply_to(cents)
    cents - (cents * percent_off / 100.0).round
  end
end
