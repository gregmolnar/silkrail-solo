store = StoreSetting.current
store.update!(
  name: ENV.fetch("STORE_NAME", store.name),
  description: ENV.fetch("STORE_DESCRIPTION", "Independent digital goods, sold directly."),
  support_email: ENV["STORE_SUPPORT_EMAIL"]
)

email = ENV.fetch("ADMIN_EMAIL", "owner@example.com")
user = User.find_or_initialize_by(email_address: email)
user.name = ENV.fetch("ADMIN_NAME", "Store owner")
if user.new_record?
  user.password = ENV.fetch("ADMIN_PASSWORD", "change-me-now-123")
  user.password_confirmation = user.password
end
user.save!

Purchase.distinct.pluck(:email).each { |purchase_email| Customer.for_email(purchase_email) }

puts "Store ready. Sign in as #{email}."
puts "WARNING: Set ADMIN_PASSWORD before seeding production." unless ENV["ADMIN_PASSWORD"]
