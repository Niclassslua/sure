class Settings::AccountApisController < ApplicationController
  layout "settings"

  def show
    @accounts = Current.family.accounts.order(:name)
    @account = @accounts.find_by(id: params[:account_id])
  end

  def update
    account = Current.family.accounts.find(update_params[:account_id])
    account.update!(fints_api_base_url: update_params[:fints_api_base_url].presence)
    redirect_to settings_account_api_path(account_id: account.id), notice: "API updated"
  end

  private

    def update_params
      params.permit(:account_id, :fints_api_base_url)
    end
end
