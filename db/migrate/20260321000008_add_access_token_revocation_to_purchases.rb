class AddAccessTokenRevocationToPurchases < ActiveRecord::Migration[8.1]
  def change
    add_column :purchases, :access_token_revoked_at, :datetime
  end
end
