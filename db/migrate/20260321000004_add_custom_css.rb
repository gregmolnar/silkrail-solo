class AddCustomCss < ActiveRecord::Migration[8.1]
  GENERAL_CSS = <<~CSS
    /*
     * General storefront styles
     *
     * Available elements:
     * body.storefront-body
     * .store-header, .store-brand, .store-main, .store-footer
     * .store-hero, .store-eyebrow, .store-title, .store-description
     * .product-grid, .product-card, .product-card-image
     * .product-card-body, .product-card-title, .product-card-price
     * .product-card-summary, .product-purchase-card, .buy-button
     * .release-card
     */
    :root {
      --store-background: #f8f6f1;
      --store-text: #020617;
      --store-accent: #059669;
      --store-card-background: #ffffff;
      --store-border: rgba(15, 23, 42, 0.10);
    }

    body.storefront-body {
      background: var(--store-background);
      color: var(--store-text);
    }

    .store-eyebrow,
    .product-kicker {
      color: var(--store-accent);
    }

    .product-card,
    .product-purchase-card,
    .release-card {
      background: var(--store-card-background);
      border-color: var(--store-border);
    }

    .buy-button {
      background: var(--store-accent);
    }
  CSS

  PRODUCT_CSS = <<~CSS
    /*
     * Product page styles
     *
     * Available elements:
     * body.product-page, body.product-page--PRODUCT-SLUG
     * .product-layout, .product-content, .product-cover
     * .product-kicker, .product-title, .product-summary
     * .product-description, .product-purchase-sidebar
     * .product-purchase-card, .product-price
     * .discount-code-label, .discount-code-input
     * .buy-button, .secure-checkout-note
     */
    .product-page {
      --product-accent: var(--store-accent);
    }

    .product-page .product-kicker {
      color: var(--product-accent);
    }

    .product-page .buy-button {
      background: var(--product-accent);
    }
  CSS

  def change
    add_column :store_settings, :custom_css, :text, null: false, default: GENERAL_CSS
    add_column :products, :custom_css, :text, null: false, default: PRODUCT_CSS
  end
end
