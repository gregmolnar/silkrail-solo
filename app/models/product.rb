class Product < ApplicationRecord
  has_rich_text :description

  enum :status, { draft: "draft", published: "published" }, validate: true
  monetize :price_cents, numericality: { greater_than_or_equal_to: 0 }

  has_one_attached :cover
  has_many :releases, dependent: :destroy
  has_many :discount_codes, dependent: :destroy
  has_many :purchases, dependent: :restrict_with_error
  has_many :product_updates, dependent: :destroy

  before_validation :set_slug
  normalizes :slug, with: ->(slug) { slug.to_s.parameterize }

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  def stripe_product_data
    { name: name }.tap do |data|
      data[:description] = summary.truncate(500) if summary.present?
    end
  end

  private

  def set_slug
    self.slug = name if slug.blank?
  end
end
