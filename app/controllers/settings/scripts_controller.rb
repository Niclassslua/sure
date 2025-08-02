require "fileutils"

class Settings::ScriptsController < ApplicationController
  layout "settings"

  def show
    @accounts = Current.family.accounts.order(:name)
    @account = @accounts.find_by(id: params[:account_id])
    if @account&.sync_script_path.present? && File.exist?(@account.sync_script_path)
      @script_contents = File.read(@account.sync_script_path)
    end
  end

  def update
    account = Current.family.accounts.find(update_params[:account_id])
    if update_params[:script].present?
      dir = Rails.root.join("storage", "scripts")
      FileUtils.mkdir_p(dir)
      path = dir.join("account_#{account.id}.py")
      File.open(path, "wb") { |f| f.write(update_params[:script].read) }
      account.update!(sync_script_path: path.to_s)
    end
    redirect_to settings_script_path(account_id: account.id), notice: "Script updated"
  end

  private

    def update_params
      params.permit(:account_id, :script)
    end
end
