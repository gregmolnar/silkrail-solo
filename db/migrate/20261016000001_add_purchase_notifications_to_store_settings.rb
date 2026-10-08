class AddPurchaseNotificationsToStoreSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :store_settings, :purchase_notifications_enabled, :boolean, default: false, null: false
  end
end
