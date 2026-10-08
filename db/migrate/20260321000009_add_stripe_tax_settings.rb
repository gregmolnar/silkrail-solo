class AddStripeTaxSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :store_settings, :stripe_tax_enabled, :boolean, default: false, null: false
    add_column :store_settings, :stripe_tax_behavior, :string, default: "inclusive", null: false
  end
end
