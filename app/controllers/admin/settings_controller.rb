class Admin::SettingsController < ApplicationController
  def edit
    @settings = store
    @user = Current.user
  end

  def update
    @settings = store
    @user = Current.user
    current_password_valid = !password_change? || @user.authenticate(params.dig(:user, :current_password))

    @settings.assign_attributes(settings_params)
    @user.assign_attributes(user_params)

    settings_valid = @settings.valid?
    user_valid = @user.valid?
    unless current_password_valid
      @user.errors.add(:current_password, "is incorrect")
      user_valid = false
    end

    if settings_valid && user_valid
      ApplicationRecord.transaction do
        @user.save!
        @settings.save!
      end
      redirect_to edit_admin_settings_path, notice: "Settings updated."
    else
      render :edit, formats: :html, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.expect(store_setting: %i[
      name description support_email currency custom_css stripe_tax_enabled stripe_tax_behavior purchase_notifications_enabled
      privacy_policy terms_of_service refund_policy seller_information
    ])
  end

  def user_params
    permitted = params.expect(user: %i[name email_address password password_confirmation])
    permitted[:password].blank? ? permitted.except(:password, :password_confirmation) : permitted
  end

  def password_change?
    params.dig(:user, :password).present?
  end
end
