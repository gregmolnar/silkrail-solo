class StripeEvent < ApplicationRecord
  validates :stripe_id, presence: true, uniqueness: true
end
