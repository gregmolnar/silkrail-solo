require "bigdecimal"
require "csv"

class Admin::ProductPurchasesController < ApplicationController
  before_action :set_product

  def new
    @purchase = @product.purchases.new(
      amount_cents: @product.price_cents,
      currency: store.currency,
      source: :manual
    )
    @purchased_at = Time.current
  end

  def create
    @purchased_at = parse_gumroad_time(purchase_params[:purchased_at])
    @purchase = @product.purchases.new(
      email: purchase_params[:email],
      amount_cents: money_to_cents(purchase_params[:amount]),
      currency: store.currency,
      source: purchase_params[:source].presence || :manual,
      external_id: purchase_params[:external_id].presence
    )
    @purchase.created_at = @purchased_at if @purchased_at
    @purchase.updated_at = @purchased_at if @purchased_at

    if @purchase.valid?
      @purchase.customer = Customer.for_email(@purchase.email)
      @purchase.save!
      PurchaseMailer.receipt(@purchase).deliver_later if ActiveModel::Type::Boolean.new.cast(purchase_params[:send_receipt])
      redirect_to admin_purchase_path(@purchase), notice: "Purchase added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def import; end

  def import_create
    unless params[:gumroad_csv].present?
      redirect_to import_admin_product_purchases_path(@product), alert: "Please choose a CSV file to import."
      return
    end

    imported = 0
    skipped = 0

    CSV.parse(params[:gumroad_csv].read, headers: true, liberal_parsing: true, header_converters: ->(header) { header&.delete_prefix("\uFEFF")&.strip }) do |row|
      item_name = row["Item Name"].to_s.strip
      next if item_name == "Totals"

      unless item_name == @product.name
        skipped += 1
        next
      end

      email = row["Purchase Email"].presence || row["Buyer Email"].presence
      unless email.present?
        skipped += 1
        next
      end

      purchased_at = parse_gumroad_time(row["Purchase Time (UTC timezone)"].presence || row["Purchase Date"].presence)
      customer = Customer.for_email(email)
      attributes = {
        customer: customer,
        email: email,
        amount_cents: money_to_cents(row["Sale Price ($)"].presence || row["Item Price ($)"].presence),
        currency: "usd",
        source: "gumroad",
        external_id: gumroad_id(row)
      }
      attributes[:created_at] = purchased_at if purchased_at
      attributes[:updated_at] = purchased_at if purchased_at

      if @product.purchases.create(attributes).persisted?
        imported += 1
      else
        skipped += 1
      end
    end

    message = "Imported #{imported} #{'purchase'.pluralize(imported)} from Gumroad."
    message += " Skipped #{skipped}." if skipped.positive?
    redirect_to admin_purchases_path(product_id: @product), notice: message
  rescue CSV::MalformedCSVError => error
    redirect_to import_admin_product_purchases_path(@product), alert: "Could not import CSV: #{error.message}"
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def purchase_params
    params.expect(purchase: %i[email amount source purchased_at external_id send_receipt])
  end

  def parse_gumroad_time(value)
    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def money_to_cents(value)
    (BigDecimal(value.to_s) * 100).round.to_i
  rescue ArgumentError
    0
  end

  def gumroad_id(row)
    (row["Sale ID"].presence || row["Order Number"].presence).to_s.strip.presence
  end
end
