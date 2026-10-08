class AddCustomerAccountsAndProductUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.timestamps
      t.index :email_address, unique: true
    end

    create_table :customer_sessions do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    add_reference :purchases, :customer, foreign_key: true

    create_table :product_updates do |t|
      t.references :product, null: false, foreign_key: true
      t.string :subject, null: false
      t.text :body, null: false
      t.datetime :sent_at
      t.timestamps
    end
  end
end
