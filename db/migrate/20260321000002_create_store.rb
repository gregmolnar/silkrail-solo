class CreateStore < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.timestamps
      t.index :email_address, unique: true
    end

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    create_table :store_settings do |t|
      t.string :name, null: false, default: "My Store"
      t.text :description
      t.string :support_email
      t.string :currency, null: false, default: "usd"
      t.timestamps
    end

    create_table :products do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :status, null: false, default: "draft"
      t.string :summary
      t.text :description
      t.integer :price_cents, null: false, default: 0
      t.timestamps
      t.index :slug, unique: true
      t.index :status
    end

    create_table :releases do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.string :status, null: false, default: "draft"
      t.text :notes
      t.timestamps
    end

    create_table :discount_codes do |t|
      t.references :product, null: false, foreign_key: true
      t.string :code, null: false
      t.integer :percent_off, null: false
      t.integer :max_redemptions
      t.integer :redemptions_count, null: false, default: 0
      t.datetime :expires_at
      t.timestamps
      t.index %i[product_id code], unique: true
    end

    create_table :purchases do |t|
      t.references :product, null: false, foreign_key: true
      t.references :discount_code, foreign_key: true
      t.string :email, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "usd"
      t.string :stripe_checkout_session_id, null: false
      t.string :stripe_payment_intent_id
      t.string :access_token, null: false
      t.timestamps
      t.index :stripe_checkout_session_id, unique: true
      t.index :access_token, unique: true
      t.index :email
    end

    create_table :stripe_events do |t|
      t.string :stripe_id, null: false
      t.string :event_type, null: false
      t.datetime :processed_at, null: false
      t.timestamps
      t.index :stripe_id, unique: true
    end
  end
end
