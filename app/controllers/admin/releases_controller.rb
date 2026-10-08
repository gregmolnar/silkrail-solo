class Admin::ReleasesController < ApplicationController
  before_action :set_product
  before_action :set_release, only: %i[edit update destroy]

  def index
    @releases = @product.releases.with_attached_files.order(created_at: :desc)
  end

  def new
    @release = @product.releases.new
  end

  def create
    @release = @product.releases.new(release_params)
    if @release.save
      redirect_to admin_product_releases_path(@product), notice: "Release created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    purge_removed_files
    if @release.update(release_params)
      redirect_to admin_product_releases_path(@product), notice: "Release updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @release.destroy!
    redirect_to admin_product_releases_path(@product), notice: "Release deleted."
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def set_release
    @release = @product.releases.find(params[:id])
  end

  def release_params
    params.expect(release: [ :name, :status, :notes, { files: [] } ])
  end

  def purge_removed_files
    @release.files.attachments.where(id: Array(params.dig(:release, :remove_file_ids))).each(&:purge)
  end
end
