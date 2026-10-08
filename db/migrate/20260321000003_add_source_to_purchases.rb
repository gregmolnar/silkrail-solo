class AddSourceToPurchases < ActiveRecord::Migration[8.1]
  def change
    change_column_null :purchases, :stripe_checkout_session_id, true
    add_column :purchases, :source, :string, null: false, default: "stripe"
    add_column :purchases, :external_id, :string
    add_index :purchases, %i[source external_id], unique: true, where: "external_id IS NOT NULL"
  end
end
