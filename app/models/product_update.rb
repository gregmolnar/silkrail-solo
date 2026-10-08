class ProductUpdate < ApplicationRecord
  belongs_to :product
  has_rich_text :body

  validates :subject, :body, presence: true
end
