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
    dir = Rails.root.join("storage", "scripts", "account_#{account.id}")
    FileUtils.mkdir_p(dir)

    if update_params[:script].present?
      path = dir.join("script.py")
      File.open(path, "wb") { |f| f.write(update_params[:script].read) }
      File.chmod(0o600, path)
      account.update!(sync_script_path: path.to_s)
    end

    if update_params[:requirements].present?
      req_path = dir.join("requirements.txt")
      File.open(req_path, "wb") { |f| f.write(update_params[:requirements].read) }
      File.chmod(0o600, req_path)
    end

    if update_params[:env].present?
      env_path = dir.join(".env")
      File.open(env_path, "wb") { |f| f.write(update_params[:env].read) }
      File.chmod(0o600, env_path)
    end

    redirect_to settings_script_path(account_id: account.id), notice: "Script updated"
  end

  private

    def update_params
      params.permit(:account_id, :script, :requirements, :env)
    end
end
