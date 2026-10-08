Money.rounding_mode = BigDecimal::ROUND_HALF_UP
Money.locale_backend = nil

MoneyRails.configure do |config|
  config.default_currency = :usd
end
