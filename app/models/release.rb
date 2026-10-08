class Release < ApplicationRecord
  belongs_to :product
  has_many_attached :files
  has_rich_text :notes
  enum :status, { draft: "draft", published: "published" }, validate: true

  validates :name, presence: true
end
